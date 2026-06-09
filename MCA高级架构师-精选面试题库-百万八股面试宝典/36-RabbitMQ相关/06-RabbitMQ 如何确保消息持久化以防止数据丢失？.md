在 RabbitMQ 中实现消息持久化，需要从以下几个方面保障，并可引入高可用机制确保系统在故障恢复后依然稳定运行。

### 1. 保证交换机和队列持久（Durable）

为了在 Broker 重启后继续保留交换机和队列的元数据，声明时必须启用 `durable=true`。这一步不仅保留队列结构，也为后续消息恢复奠定基础。

```java
channel.exchangeDeclare("logs", "fanout", true);
channel.queueDeclare("task_queue", true, false, false, null);
```

此举确保结构持久，但并不代表消息已落盘。

### 2. 标记消息为持久（Persistent 消息）

发布消息时，通过设置 `delivery_mode=2` 或 `persistent=true`，将其写入磁盘：

```java
AMQP.BasicProperties props = new AMQP.BasicProperties.Builder()
.deliveryMode(2)
.build();
channel.basicPublish("logs", "", props, messageBody);
```

这样，消息即使暂存在内存，也会被后台异步持久化。

### 3. 使用 Publisher Confirms 确认写入安全

启用 Confirm 模式 (`confirm.select()`)，并等待 Broker 返回 `ack`，确保消息已被持久化到磁盘。若未收到 ack，可做重试处理 — 实现真正的 **至少写盘一次**。

### 4. 可选：配置高可用队列类型

- **Quorum 队列** 或 **镜像（Classic Mirrored）队列**将消息复制到多个节点，即使某节点崩溃，其他节点也能提供副本；
- **Lazy Queues** 配合持久消息可缓解内存压力，实现大容量持久化存储。
