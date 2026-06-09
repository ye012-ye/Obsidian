---
title: "RabbitMQ 高级篇：集群、镜像队列与 Quorum Queue"
tags:
  - rabbitmq
  - 消息队列
  - 集群
  - 高可用
  - quorum
  - 分布式
aliases:
  - RabbitMQ 集群
  - Quorum Queue 教程
  - 镜像队列
难度级别: 高级
---

单机 RabbitMQ 适合做 demo，真正上生产必须谈集群。这一章把集群拓扑、三种队列类型（Classic / Quorum / Stream）、网络分区处理、跨集群方案一次性讲透。本章假设你已经看过 [[06-进阶-消息可靠性与事务确认]]，对 publisher confirm、持久化、ack 不陌生。

## 1. 为什么要集群

单节点 RabbitMQ 有两个致命问题：

1. **可用性**：节点宕机，整个 broker 不可达，所有 producer/consumer 全部断连。
2. **吞吐天花板**：一台机器的 CPU、内存、磁盘 IO 总有上限，单 vhost 的消息量增长到一定程度后再也压不动。

集群解决两件事：

- **高可用 (HA)**：一个节点挂了，其他节点继续提供服务。
- **横向扩展 (Scale-out)**：连接、信道、Exchange 路由计算分散到多个节点，提升整体吞吐。

> [!warning] 注意
> RabbitMQ 集群默认 **不会** 自动让队列高可用。元数据（Exchange、Binding、vhost、user）会在所有节点同步，但 **经典队列（Classic Queue）的数据只在创建它的那个节点上**。这点是 RabbitMQ 集群最容易踩坑的地方，下面会反复强调。

## 2. 集群架构与元数据同步

```mermaid
graph TB
    subgraph "RabbitMQ Cluster"
        N1[Node1<br/>disc<br/>queue_A 主]
        N2[Node2<br/>disc<br/>queue_B 主]
        N3[Node3<br/>ram<br/>无队列主]
    end
    C1[Producer] -->|connect| N1
    C2[Producer] -->|connect| N2
    Cons1[Consumer] -->|connect| N3
    N3 -.转发请求.-> N1
    N3 -.转发请求.-> N2

    style N1 fill:#e8f5e9
    style N2 fill:#e8f5e9
    style N3 fill:#fff3e0
```

集群内部同步的元数据：

| 元数据类型 | 是否所有节点同步 | 说明 |
|---|---|---|
| Queue 定义（名字、参数） | ✓ | 任意节点都能查到队列存在 |
| Exchange 定义 | ✓ | 路由表全局可见 |
| Binding | ✓ | 路由规则全局可见 |
| vhost / user / permission | ✓ | 权限统一 |
| **Classic 队列的消息数据** | ✗ | 只在 owner 节点 |
| Quorum 队列的消息数据 | ✓ | Raft 复制到所有副本 |

如果 Consumer 连到 Node3 但要消费 `queue_A`（在 Node1 上），Node3 会做一次内部转发，把消息从 Node1 拉过来。这条转发链路在网络分区时会出问题，所以裸用经典队列做集群其实没有真正的 HA。

## 3. 集群搭建步骤

下面给出三节点最小可用集群（rabbit1/rabbit2/rabbit3）的搭建步骤，假设系统是 Linux。

### 3.1 配置 hostname 与 hosts

```bash
# 每个节点都执行（举例 rabbit1）
hostnamectl set-hostname rabbit1

# 三台机器都加到 /etc/hosts
cat >> /etc/hosts <<EOF
192.168.1.11  rabbit1
192.168.1.12  rabbit2
192.168.1.13  rabbit3
EOF
```

> [!danger] 关键
> RabbitMQ 节点之间用 hostname 通信，必须保证三台机器互相 ping 通对方的 hostname。生产环境一定要用稳定的内网 hostname，不要用 localhost、127.0.0.1。

### 3.2 同步 Erlang Cookie

集群节点用 Erlang Cookie 做身份验证。所有节点的 cookie 必须一致：

```bash
# 在 rabbit1 上拷贝 cookie 到 rabbit2、rabbit3
scp /var/lib/rabbitmq/.erlang.cookie rabbit2:/var/lib/rabbitmq/
scp /var/lib/rabbitmq/.erlang.cookie rabbit3:/var/lib/rabbitmq/

# 修复权限
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
```

### 3.3 启动节点并加入集群

```bash
# 所有节点先独立启动
systemctl start rabbitmq-server

# 在 rabbit2 上加入 rabbit1
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app

# 在 rabbit3 上同样
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app

# 在任意节点查看集群状态
rabbitmqctl cluster_status
```

输出里看到 `running_nodes: [rabbit@rabbit1, rabbit@rabbit2, rabbit@rabbit3]` 就成功了。

## 4. 节点类型：disc vs ram

| 类型 | 元数据存储 | 适用场景 |
|---|---|---|
| **disc 节点** | 磁盘 + 内存 | 默认。元数据持久化，重启后还在 |
| **ram 节点** | 仅内存 | 高频元数据变更场景（大量声明/删除队列）。性能更高，但集群至少要有一个 disc 节点 |

```bash
# 把节点改成 ram 类型
rabbitmqctl stop_app
rabbitmqctl change_cluster_node_type ram
rabbitmqctl start_app
```

> [!tip] 实践建议
> 生产环境 95% 的场景都用 disc 节点就好。ram 节点的性能优势在现代硬件上很小，反而带来运维复杂度。除非你明确遇到了元数据 IO 瓶颈，否则别折腾。

## 5. 镜像队列（Classic Mirrored Queue）

镜像队列是 RabbitMQ 3.8 之前实现经典队列 HA 的唯一方案。原理是给经典队列加副本，主队列（master）在一个节点，从队列（mirror/slave）在其他节点，通过 **GM (Guaranteed Multicast) 协议** 同步消息。

### 5.1 配置 policy

```bash
# 所有以 ha. 开头的队列在所有节点做镜像
rabbitmqctl set_policy ha-all "^ha\." \
  '{"ha-mode":"all","ha-sync-mode":"automatic"}'

# 只在指定 2 个节点做镜像
rabbitmqctl set_policy ha-two "^ha\." \
  '{"ha-mode":"exactly","ha-params":2,"ha-sync-mode":"automatic"}'

# 镜像到指定节点列表
rabbitmqctl set_policy ha-nodes "^ha\." \
  '{"ha-mode":"nodes","ha-params":["rabbit@rabbit1","rabbit@rabbit2"]}'
```

| 参数 | 含义 |
|---|---|
| `ha-mode: all` | 所有节点都做镜像 |
| `ha-mode: exactly` + `ha-params: N` | 总共 N 个副本（含主） |
| `ha-mode: nodes` + `ha-params: [list]` | 镜像到指定节点 |
| `ha-sync-mode: automatic` | 新副本自动同步历史消息 |
| `ha-sync-mode: manual` | 新副本只接收新消息，老消息需要 `rabbitmqctl sync_queue` |

### 5.2 弃用警告

> [!danger] 镜像队列已被官方废弃
> - RabbitMQ **3.8** 起官方不再推荐使用镜像队列
> - **3.10** 起标记为 deprecated
> - **4.0** 起完全移除
>
> 原因：GM 协议在网络抖动时容易脑裂，性能差，扩容时全量同步会阻塞整个队列。**新项目一律使用 Quorum Queue。** 历史项目升级时也建议尽快迁移。

## 6. Quorum Queue（强烈推荐）

Quorum Queue 是 3.8 引入的新一代高可用队列，基于 **Raft 算法**，强一致性，是镜像队列的官方替代品。

### 6.1 Raft 简介

Raft 是 Paxos 的工业化简化版，核心三件事：

1. **Leader 选举**：节点宕机时，剩余节点投票选新 Leader。
2. **日志复制**：写操作必须被多数派（quorum）确认才算成功。
3. **安全性**：保证 committed 的日志永不丢失。

```mermaid
sequenceDiagram
    participant P as Producer
    participant L as Leader (Node1)
    participant F1 as Follower (Node2)
    participant F2 as Follower (Node3)

    P->>L: publish message
    L->>L: append to log
    par 并行复制
        L->>F1: AppendEntries
        L->>F2: AppendEntries
    end
    F1-->>L: ack
    F2-->>L: ack
    Note over L: 收到多数派 ack
    L->>L: commit
    L-->>P: publisher confirm
    par 通知 commit
        L->>F1: commit
        L->>F2: commit
    end
```

3 节点集群中，写入需要至少 2 个节点（含 Leader）确认，挂掉 1 个节点仍可工作。5 节点集群可挂 2 个。

### 6.2 声明 Quorum Queue

队列类型在**声明时**指定，不能动态切换。

#### Java（Spring Boot）

```java
@Configuration
public class QuorumQueueConfig {

    @Bean
    public Queue orderQuorumQueue() {
        return QueueBuilder.durable("order.quorum")
                .withArgument("x-queue-type", "quorum")
                // 可选：副本数量，默认所有节点
                .withArgument("x-quorum-initial-group-size", 3)
                // 可选：消息投递失败重试上限，超过送 dead letter
                .withArgument("x-delivery-limit", 5)
                .build();
        }

    @Bean
    public DirectExchange orderExchange() {
        return new DirectExchange("order.exchange", true, false);
    }

    @Bean
    public Binding orderBinding(Queue orderQuorumQueue, DirectExchange orderExchange) {
        return BindingBuilder.bind(orderQuorumQueue)
                .to(orderExchange)
                .with("order.create");
    }
}
```

#### Java（原生客户端）

```java
ConnectionFactory factory = new ConnectionFactory();
factory.setHost("rabbit1");
factory.setUsername("admin");
factory.setPassword("admin");

try (Connection conn = factory.newConnection();
     Channel channel = conn.createChannel()) {

    Map<String, Object> args = new HashMap<>();
    args.put("x-queue-type", "quorum");
    args.put("x-delivery-limit", 5);

    channel.queueDeclare(
        "order.quorum",
        true,    // durable，Quorum 必须 true
        false,   // exclusive 必须 false
        false,   // autoDelete 必须 false
        args
    );
}
```

#### Python（pika）

```python
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='rabbit1', credentials=pika.PlainCredentials('admin', 'admin'))
)
channel = connection.channel()

channel.queue_declare(
    queue='order.quorum',
    durable=True,
    arguments={
        'x-queue-type': 'quorum',
        'x-delivery-limit': 5,
    }
)
```

#### Go（amqp091-go）

```go
ch, _ := conn.Channel()

_, err := ch.QueueDeclare(
    "order.quorum",
    true,  // durable
    false, // autoDelete
    false, // exclusive
    false, // noWait
    amqp.Table{
        "x-queue-type":      "quorum",
        "x-delivery-limit":  5,
    },
)
```

> [!warning] Quorum Queue 的限制
> - 必须 `durable=true`
> - 不支持 `exclusive`、`autoDelete`
> - 不支持 priority、TTL per-message（队列级 TTL 支持）
> - 内存占用比经典队列高（消息要常驻直到 commit）
> - 不能直接从经典队列迁移，需要新建队列重新消费

### 6.3 Quorum vs Classic Mirror 对比

| 维度 | Classic Mirror（已废弃） | Quorum Queue |
|---|---|---|
| 复制协议 | GM (custom) | Raft（成熟算法） |
| 一致性 | 最终一致 | 强一致（多数派 commit） |
| Leader 选举 | 主挂后从晋升，可能丢消息 | Raft 选举，已 commit 永不丢 |
| 网络分区 | 容易脑裂 | 少数派自动停写 |
| 写入吞吐 | 高（异步同步） | 较低（同步复制） |
| 读取吞吐 | 高 | 高 |
| 内存占用 | 低 | 高（日志常驻） |
| 扩容副本 | 全量同步阻塞 | 增量同步 |
| 优先级队列 | 支持 | ✗ |
| TTL per-message | 支持 | ✗ |
| 死信 | 支持 | 支持（更完善） |
| 官方推荐 | ✗ | ✓ |

## 7. Stream Queue（3.9+）

Stream 是仿 Kafka 设计的 **append-only 持久化日志**，适合：

- 海量消息（百万级 TPS）
- 消息需要被多个 consumer 重放
- 长时间保留（按时间或大小滚动）

### 7.1 声明 Stream

```java
Map<String, Object> args = new HashMap<>();
args.put("x-queue-type", "stream");
args.put("x-max-length-bytes", 20_000_000_000L);  // 20GB 滚动
args.put("x-stream-max-segment-size-bytes", 500_000_000L);  // 单段 500MB

channel.queueDeclare("events.stream", true, false, false, args);
```

消费时要用 `x-stream-offset` 指定起点：

```java
channel.basicQos(100);
channel.basicConsume(
    "events.stream",
    false,
    Map.of("x-stream-offset", "first"),  // first / last / next / 数字 offset / 时间戳
    consumerTag,
    deliverCallback,
    cancelCallback
);
```

### 7.2 三种队列类型对比

| 特性 | Classic | Quorum | Stream |
|---|---|---|---|
| 适用场景 | 简单任务队列 | 业务关键消息 | 事件流、日志、广播 |
| 持久性 | 可选 | 强制持久 | 强制持久 |
| 高可用 | 需镜像（已废弃） | 内置 Raft | 内置副本 |
| 消息模型 | 出队即删 | 出队即删 | 不删，按 offset 读 |
| 重放 | ✗ | ✗ | ✓ |
| 多消费组 | ✗ | ✗ | ✓ |
| 吞吐 | 中 | 中低 | 极高 |
| 延迟 | 低 | 中 | 中 |

> [!tip] 选型建议
> - **订单、支付、库存** → Quorum Queue（不允许丢、强一致）
> - **日志收集、用户行为埋点、审计流** → Stream Queue（量大、要重放）
> - **简单的临时通知、可丢消息** → Classic Queue（更轻量）
> - **新项目不要再用 Classic Mirror**

## 8. 客户端负载均衡

集群有多个节点，客户端连哪个？三种方案：

```mermaid
graph LR
    P1[Producer] --> LB[HAProxy<br/>5672]
    P2[Producer] --> LB
    C1[Consumer] --> LB
    LB --> N1[Node1:5672]
    LB --> N2[Node2:5672]
    LB --> N3[Node3:5672]
```

### 8.1 HAProxy 配置示例

```haproxy
frontend rabbitmq_front
    bind *:5672
    mode tcp
    timeout client 3h
    default_backend rabbitmq_back

backend rabbitmq_back
    mode tcp
    balance roundrobin
    timeout server 3h
    timeout connect 10s
    option tcp-check
    server rabbit1 192.168.1.11:5672 check inter 5s rise 2 fall 3
    server rabbit2 192.168.1.12:5672 check inter 5s rise 2 fall 3
    server rabbit3 192.168.1.13:5672 check inter 5s rise 2 fall 3
```

> [!warning] 长连接超时
> AMQP 是长连接协议，HAProxy 的 `timeout client/server` 一定要拉长（推荐 1-3 小时），否则连接会被强制断掉，触发频繁重连。

### 8.2 客户端多 endpoint（推荐）

更优雅的做法是客户端自己配多个 broker 地址，连不上自动切换：

```java
ConnectionFactory factory = new ConnectionFactory();
factory.setUsername("admin");
factory.setPassword("admin");

Address[] addresses = {
    new Address("rabbit1", 5672),
    new Address("rabbit2", 5672),
    new Address("rabbit3", 5672)
};

Connection connection = factory.newConnection(addresses);
```

Spring Boot 配置：

```yaml
spring:
  rabbitmq:
    addresses: rabbit1:5672,rabbit2:5672,rabbit3:5672
    username: admin
    password: admin
    virtual-host: /
```

## 9. 网络分区（Split-Brain）

集群节点之间网络中断，两部分都还活着，但互相看不到 → 分区。

### 9.1 检测

```bash
rabbitmqctl cluster_status
# 输出里看 partitions 字段
```

或者 management UI 上会弹出红色横幅警告。

### 9.2 三种处理策略

在 `rabbitmq.conf` 配：

```ini
cluster_partition_handling = pause_minority
```

| 策略 | 行为 | 适用场景 |
|---|---|---|
| `ignore` | 不处理，两侧都继续运行 | 跨机房、网络不稳定（默认） |
| `pause_minority` | 少数派节点自动停止接收请求，等网络恢复 | **生产推荐**，3+ 节点集群 |
| `autoheal` | 分区恢复后自动选一边 winner，其他节点重启 | 优先可用性，能接受少量数据丢失 |
| `pause_if_all_down` | 指定一组节点，只要这组全死才暂停 | 特殊拓扑 |

> [!danger] 一定要配 pause_minority
> 默认的 `ignore` 在分区时两侧都接受写入，恢复后冲突无法自动合并，必然丢消息。**3+ 节点集群必须配 `pause_minority`**。2 节点集群没办法判断多数派，建议至少做 3 节点。

## 10. 跨集群方案：Federation 与 Shovel

集群解决单机房 HA，**跨机房**需要 Federation 或 Shovel。

| 方案 | 工作方式 | 适用场景 |
|---|---|---|
| **Federation** | 在下游集群配置 upstream，自动拉取上游 exchange/queue 的消息 | 跨地域消息分发、灾备 |
| **Shovel** | 配置一个 worker，把 A 集群队列的消息搬到 B 集群 | 集群迁移、单向同步、过滤搬运 |

简单配置示例（Shovel）：

```bash
rabbitmqctl set_parameter shovel my-shovel \
  '{"src-protocol":"amqp091","src-uri":"amqp://user:pass@source-host","src-queue":"orders",
    "dest-protocol":"amqp091","dest-uri":"amqp://user:pass@dest-host","dest-queue":"orders.replica"}'
```

> [!note] 区别记忆
> - Federation **保持原始路由语义**，像在下游集群"代理"一个上游 exchange。
> - Shovel 更像一个 ETL 搬运工，只关心"从哪搬到哪"，可以做协议转换、过滤。

## 11. 常见面试题

> [!question] Quorum Queue 的选举原理是什么？
> 基于 Raft 算法。每个节点有 term（任期），Follower 在 election timeout 内没收到 Leader 心跳就转为 Candidate，自增 term 并发起投票。获得多数派投票的节点成为新 Leader。Leader 通过 AppendEntries RPC 复制日志并维持心跳。任何 committed 的日志保证不会丢失。

> [!question] 镜像队列的 GM 协议是什么？为什么差？
> GM (Guaranteed Multicast) 是 RabbitMQ 自己实现的组播协议，所有镜像节点组成一个环，消息按环顺序广播。缺点：
> 1. 不是真正的共识算法，网络抖动时主从可能不一致
> 2. 主挂后从晋升期间已发但未同步的消息会丢
> 3. 扩容新副本要全量同步，期间队列阻塞
> 4. 性能在多副本下退化严重

> [!question] 为什么 Quorum Queue 比镜像队列更好？
> 1. **强一致性**：基于 Raft，已 commit 的消息绝不丢失
> 2. **明确的故障语义**：多数派存活才可写，避免脑裂
> 3. **性能可预测**：增量复制，扩缩容不阻塞
> 4. **更完善的死信与重试**：内置 `x-delivery-limit`
> 5. **官方主推**：未来所有新功能围绕 Quorum/Stream，Classic 已废弃

> [!question] 集群中 Producer 连 NodeA，要发到 NodeB 上的队列，怎么发生的？
> Producer 把消息发给 NodeA，NodeA 根据 Exchange 路由计算出目标队列在 NodeB，通过节点间内部连接（25672 端口）转发给 NodeB。这个转发增加了延迟和 NodeA 的网络负担。所以经典队列要尽量让 Producer 直连队列所在节点，或者用 Quorum/Stream 彻底回避这个问题。

> [!question] 集群至少需要几个节点？为什么？
> - **2 节点**：能容忍 0 个故障（分区时无法判断多数派），不推荐
> - **3 节点**：能容忍 1 个故障，**生产最低配置**
> - **5 节点**：能容忍 2 个故障，金融级场景
> - 副本数 = `2N+1`，写入需要 `N+1` 个节点确认

> [!question] Erlang Cookie 是什么作用？
> Erlang 节点之间通信的身份令牌。两个 Erlang 节点要互通，cookie 必须完全一致。RabbitMQ 基于 Erlang/OTP，集群通信本质是 Erlang 节点互联，所以所有集群节点的 `.erlang.cookie` 必须相同。

## 12. 延伸阅读

- [[01-入门-RabbitMQ核心概念]] - Exchange / Queue / Binding 基础回顾
- [[06-进阶-消息可靠性与事务确认]] - publisher confirm 与 ack 机制，是理解 Quorum 写入语义的前提
- [[08-高级-性能调优与监控]] - Quorum 队列的 GC、内存高水位、Prometheus 监控
- [[09-实战-电商订单系统消息架构]] - 把本章知识落到真实业务场景
- 官方文档：
  - [Quorum Queues](https://www.rabbitmq.com/docs/quorum-queues)
  - [Streams](https://www.rabbitmq.com/docs/streams)
  - [Clustering Guide](https://www.rabbitmq.com/docs/clustering)
  - [Partitions](https://www.rabbitmq.com/docs/partitions)
- 论文：In Search of an Understandable Consensus Algorithm (Raft, Diego Ongaro 2014)

> [!tip] 下一步
> 看完本章你应该能独立搭建 3 节点 Quorum 集群，并理解为什么不再用镜像队列。下一章 [[08-高级-性能调优与监控]] 会讲怎么把这套集群压榨到极限，并通过 Prometheus + Grafana 把运行状态可视化。
