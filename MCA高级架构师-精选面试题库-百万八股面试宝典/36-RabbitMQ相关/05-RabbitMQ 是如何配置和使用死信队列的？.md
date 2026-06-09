在 RabbitMQ 中，死信队列（DLQ）是一种用于处理无法正常消费消息的机制，通过特定配置将“死信”自动路由至专用队列，以避免主队列堵塞并帮助故障分析。M

首先，需要在主队列上配置三项参数：`x-dead-letter-exchange` 指定死信走向的 Exchange，`x-dead-letter-routing-key` 定义转发时使用的路由键，`x-message-ttl` 可选，用于控制消息过期后自动转入 DLQ。例如：

```java
channel.queueDeclare("main_queue", true, false, false, Map.of(
    "x-dead-letter-exchange", "dlx_exchange",
    "x-dead-letter-routing-key", "dlx_key",
    "x-message-ttl", 60000  // TTL 60 秒
));
```

当消息因以下原因成为“死信”时，它将被转发：

1. 被消费者 `reject()` 或 `nack()` 且 `requeue=false`；
2. 到达 TTL 后未被消费；
3. 队列达到最大长度，消息被丢弃；
4. 对于 Quorum 队列，超过最大重试次数也归为死信。

接着，需创建与 DLX 配合的死信交换机和队列：S

```java
channel.exchangeDeclare("dlx_exchange", "direct", true);
channel.queueDeclare("dlx_queue", true, false, false, null);
channel.queueBind("dlx_queue", "dlx_exchange", "dlx_key");
```

这样，当主队列中消息变为死信时，Broker 会将它重新发布到 `dlx_exchange`，并根据绑定转至 `dlx_queue`；同时，消息头会附上 `x-death` 等元数据，包括原始队列、死信原因及次数等，可供消费端分析与决策。

应用程序可以为死信队列注册消费者，处理或记录失败消息，决定是否重试、报警或持久化存储。通常建议结合 TTL 和 DLQ 实现重试机制：

- 配置一个延时重试队列（TTL + DLX 回主队列），回退几次后最终转入 DLQ；
- 或由专用服务处理 DLQ 中的异常消息，防止无限循环。

这样主队列不会被阻塞，系统能优雅应对消费失败或异常。

B
