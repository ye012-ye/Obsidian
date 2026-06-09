---
title: "RabbitMQ 入门：核心概念与 AMQP 协议"
tags:
  - rabbitmq
  - 消息队列
  - amqp
  - 中间件
  - 入门
aliases:
  - RabbitMQ 第一课
  - AMQP 协议入门
  - RabbitMQ 核心模型
难度级别: 入门
---

# RabbitMQ 入门：核心概念与 AMQP 协议

## 一、RabbitMQ 是什么

RabbitMQ 是一个用 **Erlang** 编写的开源消息中间件（Message Broker），它实现了 **AMQP 0-9-1**（Advanced Message Queuing Protocol）协议，同时通过插件机制兼容 MQTT、STOMP、HTTP、WebSocket 等多种协议。

它在工程里扮演的角色非常直白：**应用 A 把消息丢给 broker，应用 B 从 broker 拿消息**。中间这个 broker 替你解决了网络抖动、消费速率不一致、消费者宕机、消息可靠性、路由分发等一系列脏活累活。

> [!note] 为什么选 Erlang 实现
> Erlang/OTP 天生为高并发、分布式、软实时电信系统设计，"轻量级进程 + 消息传递"的模型和 broker 的需求几乎是天作之合。这也是为什么 RabbitMQ 单机能轻松扛住几万 TPS、集群间通信延迟极低的根本原因。代价是：Erlang 在国内不算主流语言，运维门槛比纯 JVM 中间件略高。

### 为什么需要消息队列

消息队列（MQ）解决的核心问题就三个字：**解耦、削峰、异步**。我把它们拆开讲。

> [!example] 解耦（Decoupling）
> 下单服务原本要直接调用：库存服务、积分服务、短信服务、推荐服务……一旦其中任何一个挂掉，下单链路整个崩溃。引入 MQ 后，下单服务只需要把"订单已创建"这条消息丢到 broker，下游想消费就消费，挂了重启后还能接着消费。**调用方再也不需要知道下游是谁、有几个、在哪。**

> [!example] 削峰（Peak Shaving）
> 秒杀场景一秒进来 10 万请求，数据库每秒只能处理 5000 写入。直接打 DB 必崩。把请求写入 MQ，让消费者按 5000/s 的速率匀速消费，**用排队换稳定**。代价是用户感知的"下单到结果返回"会变成异步反馈。

> [!example] 异步（Async）
> 注册流程：写库 50ms + 发短信 800ms + 发邮件 600ms + 初始化推荐 400ms = 1850ms。把后三个改成异步消息，注册接口的响应时间立刻降到 50ms，**用户体验提升一个量级**。

> [!warning] MQ 不是银弹
> 引入 MQ 同时引入了：消息丢失、消息重复、消息顺序、数据一致性（最终一致而非强一致）、运维复杂度。如果你的系统调用关系简单、流量平稳、对一致性要求强（比如金融转账核心链路），就别为了"看起来高大上"硬塞一个 MQ 进去。

---

## 二、AMQP 0-9-1 核心模型

AMQP 是一个**应用层协议**，和 HTTP 同一个层级，但它面向的是消息传递场景。RabbitMQ 主推的是 0-9-1 版本（而不是后来标准化失败的 1.0），所以本系列默认讨论的都是 0-9-1。

### 七个核心概念

| 概念 | 角色定位 | 通俗解释 |
|------|---------|---------|
| Producer | 生产者 | 写消息的应用 |
| Connection | 连接 | 客户端到 broker 的 TCP 连接 |
| Channel | 信道 | 跑在 Connection 上的逻辑通道，真正干活的对象 |
| Exchange | 交换机 | 收消息、按规则路由消息 |
| Queue | 队列 | 存消息的地方，消费者从这里读 |
| Binding | 绑定 | Exchange 和 Queue 之间的路由规则 |
| Consumer | 消费者 | 读消息的应用 |

> [!tip] 一个反直觉的点
> 在 AMQP 模型里，**Producer 从来不直接把消息发给 Queue**，它只会发给 Exchange。是 Exchange 根据 routing key 和 binding 规则决定消息进哪些 Queue（可能是 0 个、1 个或多个）。这个设计是 AMQP 灵活路由能力的根本来源。

### 消息流转时序图

```mermaid
sequenceDiagram
    autonumber
    participant P as Producer
    participant Conn as Connection (TCP)
    participant Ch as Channel
    participant X as Exchange
    participant Q as Queue
    participant C as Consumer

    P->>Conn: 1. 建立 TCP 连接 (默认 5672)
    P->>Ch: 2. 在 Connection 上开 Channel
    P->>X: 3. basic.publish(exchange, routingKey, body)
    X->>X: 4. 根据 type + binding 计算路由
    X->>Q: 5. 投递消息到匹配的 Queue
    Q->>Q: 6. 持久化 / 内存暂存
    C->>Conn: 7. 建立 Connection + Channel
    C->>Q: 8. basic.consume 订阅 Queue
    Q->>C: 9. 推送消息 (push 模式)
    C->>C: 10. 业务处理
    C->>Q: 11. basic.ack 确认
    Q->>Q: 12. 删除已确认消息
```

> [!question] 为什么要分 Connection 和 Channel？
> TCP 连接的建立和销毁是昂贵的（三次握手、TLS 协商、文件描述符占用）。如果每个生产/消费线程都开一个 TCP 连接，几百个线程就把 broker 的连接数打爆了。AMQP 的做法是：**一个 Connection 上复用多个 Channel**，每个线程独占一个 Channel，broker 内部用 channel id 多路复用。本质上是 HTTP/2 stream 那一套思路在消息协议上的实现。

### Channel 使用准则

> [!danger] Channel 不是线程安全的
> 不要在多个线程间共享同一个 Channel。Spring AMQP 的 `RabbitTemplate` 内部用了 Channel 池来回避这个坑，但你自己用原生客户端时必须遵循"**一个线程一个 Channel**"。

---

## 三、消息的完整结构

一条 AMQP 消息由三部分组成：

```mermaid
flowchart LR
    A[Message] --> B[Routing Key<br/>路由键]
    A --> C[Properties<br/>属性元数据]
    A --> D[Headers<br/>头部 KV]
    A --> E[Payload<br/>消息体]

    C --> C1[content-type]
    C --> C2[delivery-mode]
    C --> C3[priority]
    C --> C4[expiration TTL]
    C --> C5[message-id]
    C --> C6[correlation-id]
    C --> C7[reply-to]
    C --> C8[timestamp]
```

### 三类字段的职责

| 字段 | 用途 | 举例 |
|------|-----|------|
| Routing Key | 给 Exchange 看的"地址"，参与路由计算 | `order.created.vip` |
| Properties | AMQP 协议预定义的元数据 | `delivery-mode=2`（持久化）、`priority=5` |
| Headers | 业务自定义的 KV，可被 headers exchange 用于路由 | `{"region":"cn","tenant":"acme"}` |
| Payload | 真正的消息体，broker 不解析 | JSON、Protobuf、二进制都行 |

> [!tip] payload 不要塞大文件
> RabbitMQ 不是文件传输系统。payload 建议控制在 **128KB 以内**，最大别超过 1MB。大对象走对象存储（S3/MinIO），消息体里只放引用 URL。否则会严重拖垮 broker 的内存和磁盘 IO。

---

## 四、vhost 与权限模型

### vhost 是什么

vhost（virtual host）是 RabbitMQ 里的**逻辑隔离单元**，可以理解成 MySQL 里的 database、K8s 里的 namespace。每个 vhost 拥有独立的：

- Exchange 命名空间
- Queue 命名空间
- Binding
- 用户权限

> [!note] 默认 vhost
> RabbitMQ 启动后会创建一个名为 `/` 的默认 vhost。生产环境强烈建议按业务线/环境拆分 vhost，比如 `/payment-prod`、`/order-prod`、`/log-test`。

### 用户权限模型

RabbitMQ 的权限是 **(user, vhost, permission)** 三元组，permission 有三种正则：

| 权限 | 含义 | 涉及的操作 |
|------|------|---------|
| configure | 配置权限 | declare/delete exchange、queue |
| write | 写权限 | publish 消息、绑定 queue 到 exchange |
| read | 读权限 | consume、get 消息、把 queue 绑到 exchange |

授权示例（CLI）：

```bash
# 创建 vhost
rabbitmqctl add_vhost /order-prod

# 创建用户
rabbitmqctl add_user order_app 'StrongPass!23'

# 授予权限：在 /order-prod 这个 vhost 下，所有资源都有 configure/write/read
rabbitmqctl set_permissions -p /order-prod order_app '.*' '.*' '.*'

# 只允许消费 order.* 队列、不允许声明 exchange
rabbitmqctl set_permissions -p /order-prod order_consumer '^$' '^$' '^order\..*'
```

> [!warning] 不要用 guest 账号上生产
> 默认的 `guest` 用户密码也是 `guest`，只允许从 `localhost` 登录。一旦你改了配置允许远程登录，整个 broker 就裸奔。**生产环境第一件事：删 guest，建专属账号。**

---

## 五、相关协议横向对比

| 维度 | JMS | AMQP 0-9-1 | MQTT | STOMP |
|------|-----|-----------|------|-------|
| 类型 | Java API 规范 | 网络线协议 | 网络线协议 | 网络线协议 |
| 语言绑定 | 仅 Java/JVM | 全语言 | 全语言 | 全语言 |
| 模型 | P2P + Pub/Sub | Exchange + Queue（更灵活） | 主题树 + QoS 等级 | 简单的 destination |
| 典型场景 | Java 企业内部 | 通用消息总线 | IoT、移动端推送 | 浏览器/脚本接入 |
| 报文开销 | 中 | 中 | 极小（2 字节起） | 中（文本协议） |
| 路由能力 | 弱（靠 selector） | 强（4 种 exchange） | 中（topic 通配） | 弱 |
| 代表实现 | ActiveMQ | RabbitMQ | EMQX、Mosquitto | ActiveMQ |

> [!tip] 协议选型口诀
> 强路由 + 多语言通用业务消息 → **AMQP / RabbitMQ**；IoT 弱网海量设备 → **MQTT**；浏览器轻量接入 → **STOMP over WebSocket**；纯 Java 老系统 → **JMS**。RabbitMQ 通过插件可以同时支持上述全部，这也是它能"通吃"的原因之一。

---

## 六、使用场景

> [!example] 适合 RabbitMQ 的场景
> - **订单异步处理**：下单成功后异步触发库存、积分、通知。
> - **任务分发（Work Queue）**：图片压缩、PDF 生成、视频转码等耗时任务分发到 worker 集群。
> - **日志/审计事件**：业务系统把审计事件丢到 fanout exchange，多个下游（ES、风控、BI）各取所需。
> - **RPC 调用**：基于 `reply-to` + `correlation-id` 实现请求-响应模式。
> - **延迟任务**：配合 `rabbitmq-delayed-message-exchange` 插件做定时取消订单、定时提醒。
> - **跨系统解耦**：微服务间事件驱动通信，CQRS / Event Sourcing 落地。

> [!danger] 不适合 RabbitMQ 的场景
> - **超高吞吐数据流**（百万 TPS 以上）→ 选 **Kafka**。Kafka 的 sequential IO + zero-copy 架构是为吞吐设计的；RabbitMQ 单 queue 受限于 Erlang 进程模型，到几万 TPS 就吃力了。
> - **海量历史消息回溯**→ 选 **Kafka**。RabbitMQ 的 queue 一旦消费就删除（除非用 stream），不适合做事件回放。
> - **大数据 ETL pipeline**→ 选 **Kafka / Pulsar**。
> - **强实时 IoT 设备接入（百万长连接）**→ 选 **EMQX / MQTT broker**。
> - **跨数据中心地理分布的事件总线**→ 选 **Pulsar / Kafka MirrorMaker**。

下一篇 [[02-入门-安装部署与HelloWorld]] 会带你把环境真正跑起来。

---

## 七、最小可运行示例

### Java（Spring Boot）

`pom.xml` 加依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

`application.yml`：

```yaml
spring:
  rabbitmq:
    host: localhost
    port: 5672
    username: order_app
    password: StrongPass!23
    virtual-host: /order-prod
```

生产者：

```java
@RestController
@RequiredArgsConstructor
public class OrderController {
    private final RabbitTemplate rabbitTemplate;

    @PostMapping("/order")
    public String create(@RequestBody OrderDTO dto) {
        // 发到 direct exchange，routing key = order.created
        rabbitTemplate.convertAndSend(
            "order.exchange",
            "order.created",
            dto,
            msg -> {
                msg.getMessageProperties().setMessageId(UUID.randomUUID().toString());
                msg.getMessageProperties().setDeliveryMode(MessageDeliveryMode.PERSISTENT);
                return msg;
            }
        );
        return "queued";
    }
}
```

消费者：

```java
@Component
public class OrderConsumer {

    @RabbitListener(bindings = @QueueBinding(
        value = @Queue(name = "order.queue", durable = "true"),
        exchange = @Exchange(name = "order.exchange", type = "direct"),
        key = "order.created"
    ))
    public void onOrder(OrderDTO dto, Channel channel,
                        @Header(AmqpHeaders.DELIVERY_TAG) long tag) throws IOException {
        try {
            // 业务处理
            log.info("处理订单 {}", dto.getId());
            channel.basicAck(tag, false);
        } catch (Exception e) {
            // 处理失败，requeue=false 让消息进入死信
            channel.basicNack(tag, false, false);
        }
    }
}
```

### Python（pika）

```python
import pika, json

params = pika.ConnectionParameters(
    host='localhost', port=5672,
    virtual_host='/order-prod',
    credentials=pika.PlainCredentials('order_app', 'StrongPass!23')
)

# 生产者
with pika.BlockingConnection(params) as conn:
    ch = conn.channel()
    ch.exchange_declare(exchange='order.exchange', exchange_type='direct', durable=True)
    ch.queue_declare(queue='order.queue', durable=True)
    ch.queue_bind('order.queue', 'order.exchange', 'order.created')

    ch.basic_publish(
        exchange='order.exchange',
        routing_key='order.created',
        body=json.dumps({'id': 1001, 'amount': 99.5}),
        properties=pika.BasicProperties(delivery_mode=2)  # 持久化
    )

# 消费者
def on_msg(ch, method, props, body):
    print('收到', body)
    ch.basic_ack(delivery_tag=method.delivery_tag)

with pika.BlockingConnection(params) as conn:
    ch = conn.channel()
    ch.basic_qos(prefetch_count=10)
    ch.basic_consume(queue='order.queue', on_message_callback=on_msg)
    ch.start_consuming()
```

### Go（amqp091-go）

```go
package main

import (
    "log"
    amqp "github.com/rabbitmq/amqp091-go"
)

func main() {
    conn, err := amqp.Dial("amqp://order_app:StrongPass!23@localhost:5672/order-prod")
    failOnError(err, "dial")
    defer conn.Close()

    ch, err := conn.Channel()
    failOnError(err, "channel")
    defer ch.Close()

    _ = ch.ExchangeDeclare("order.exchange", "direct", true, false, false, false, nil)
    q, _ := ch.QueueDeclare("order.queue", true, false, false, false, nil)
    _ = ch.QueueBind(q.Name, "order.created", "order.exchange", false, nil)

    // 生产
    _ = ch.Publish("order.exchange", "order.created", false, false, amqp.Publishing{
        ContentType:  "application/json",
        DeliveryMode: amqp.Persistent,
        Body:         []byte(`{"id":1001,"amount":99.5}`),
    })

    // 消费
    msgs, _ := ch.Consume(q.Name, "", false, false, false, false, nil)
    for d := range msgs {
        log.Printf("收到: %s", d.Body)
        _ = d.Ack(false)
    }
}

func failOnError(err error, msg string) {
    if err != nil { log.Fatalf("%s: %s", msg, err) }
}
```

> [!tip] 这段示例的隐藏知识点
> 三段代码都做了同样的事：声明 exchange + queue + binding、发消息、消费时手动 ack。注意三个细节：`durable=true`（broker 重启后保留）、`delivery-mode=2`（消息本身落盘）、`basic_qos / prefetch_count`（避免消费者被压垮）。这三件套是后面 [[04-基础-消息可靠性投递与确认机制]] 的基石，记牢。

---

## 八、常见面试题

> [!question] Q1：AMQP 0-9-1 的核心模型由哪些组件构成？请描述一条消息的完整流转过程。
>
> **答**：Producer → Connection → Channel → Exchange → Binding → Queue → Consumer。Producer 通过 Channel 发布消息到 Exchange，Exchange 根据 type 和 binding 规则把消息路由到一个或多个 Queue，Consumer 从 Queue 订阅消息，处理完成后 ack 给 broker，broker 删除消息。**关键点：Producer 永远不直接接触 Queue。**

> [!question] Q2：Channel 为什么不直接用 Connection？
>
> **答**：TCP 连接昂贵（握手、内核资源、文件描述符）。Channel 是 Connection 上的轻量级逻辑通道，多个 Channel 复用一条 TCP，broker 通过 channel id 多路复用。**一个线程一个 Channel** 是经典实践，因为 Channel 不是线程安全的。

> [!question] Q3：vhost 的作用？
>
> **答**：vhost 是 broker 内部的逻辑隔离单元，提供独立的命名空间和权限边界。可以让多个团队/业务/环境共用一套 broker 而互不干扰。本质上和 MySQL 的 database、K8s 的 namespace 是一个思路。

> [!question] Q4：RabbitMQ 和 Kafka 怎么选？
>
> **答**：看场景。RabbitMQ 强在**灵活路由、低延迟、协议丰富、运维友好**，适合业务消息、任务分发、RPC；Kafka 强在**高吞吐、持久化日志、消息回溯**，适合大数据流、日志聚合、事件溯源。不要为了"高大上"硬选 Kafka，也不要让 RabbitMQ 去扛百万 TPS。

> [!question] Q5：消息由哪些部分组成？
>
> **答**：Routing Key（路由键）+ Properties（AMQP 预定义元数据，如 delivery-mode、priority、message-id、correlation-id、reply-to、expiration）+ Headers（业务自定义 KV，可参与 headers exchange 路由）+ Payload（消息体，broker 不解析）。

> [!question] Q6：为什么不推荐用 guest 账号？
>
> **答**：默认密码公开、默认只允许 localhost 登录。一旦改配置允许远程，整个 broker 暴露。生产环境必须建独立账号并按 vhost 维度精细授权。

---

## 九、延伸阅读

- 下一篇：[[02-入门-安装部署与HelloWorld]] — Docker 单机、集群部署、Web 管理台、第一个 HelloWorld。
- 进阶：[[03-基础-Exchange四种类型详解]] — direct / fanout / topic / headers 的路由规则与适用场景。
- 可靠性：[[04-基础-消息可靠性投递与确认机制]] — publisher confirm、mandatory、return、consumer ack、事务模式。
- 官方文档（强烈建议精读）：
    - AMQP 0-9-1 Model Explained — `https://www.rabbitmq.com/tutorials/amqp-concepts`
    - RabbitMQ Tutorials（6 个官方教程，覆盖所有核心模式）
    - Access Control — `https://www.rabbitmq.com/access-control.html`
- 书籍推荐：《RabbitMQ 实战指南》朱忠华 — 国内中文资料里最系统的一本。
