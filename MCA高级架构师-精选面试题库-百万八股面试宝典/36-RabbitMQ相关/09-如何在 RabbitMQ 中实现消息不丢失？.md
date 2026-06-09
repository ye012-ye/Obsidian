在 RabbitMQ 中保障消息不丢失，需要涵盖三个关键环节：发送确认、持久化存储与消费确认。以下是详细策略：M

#### 一、发送端（生产者）：使用 Publisher Confirms

启用 Confirm 模式后，生产者在发送消息后会等待 Broker 的确认（ack）。这种机制确保消息已经被 RabbitMQ 接收并正确路由：

- 在 Channel 上调用 `confirm.select()` 激活确认模式；
- 通过回调监控 ack/nack，若 nack 或超时发生，可重试发送；
- 可结合 `mandatory` 标志，实现 unroutable 消息的回退处理。M

这种方式能及时捕获网络中断、Broker 崩溃或路由失败等问题，防止消息“悄无声息地丢失”。

#### 二、Broker 层：队列与消息持久化

确保消息顺利保存在 Broker 中，需要两个配置并配合 HA 模式：

1. **持久队列**：声明队列时设置 `durable=true`；
2. **持久消息**：发布消息时 `delivery_mode=2`，标记为持久属性；
3. **高可用队列**：使用 Quorum 队列或 Classic + mirroring 策略，在多节点间复制消息。

通过这些措施，即使节点重启、磁盘故障或网络分区，消息也不会丢失。

S

#### 三、消费端（消费者）：手动 ACK 与重试机制

抓住消费阶段的不丢失关键点：

- 关闭自动 ACK（`autoAck=false`），启用手动确认；
- 消费消息并处理成功后调用 `channel.basicAck(deliveryTag, false)`；
- 若处理失败，应使用 `basicNack(..., requeue=true)` 进行重试；
- 建议使消费逻辑具备幂等性，避免重复消费带来的副作用；
- 合理配置 `prefetch` 数量，控制流量与并发。

B
