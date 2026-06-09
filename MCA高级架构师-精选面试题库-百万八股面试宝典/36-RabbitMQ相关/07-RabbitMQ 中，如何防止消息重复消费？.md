在 RabbitMQ 中，确保消息不被重复消费（尽力实现 Exactly‑Once 或 at‑least‑once 幂等处理）需要以下多级保障：

M

### 1. 生产者端：加入唯一 ID 标记（防重投）

生产者应为每条消息设置全局唯一的 `message_id` 或 `idempotency_key`，以便后续处理环节检测重复：

- Spring-Rabbit 可设置 `AbstractMessageConverter.createMessageIds=true` 自动生成 `message_id`。
- 也可手动生成 UUID 作为标识，附加至消息属性中。

这样即使生产者因网络异常重发，消费者仍能识别重复消息并跳过处理。

S

### 2. Broker 端（RabbitMQ或插件）：辅助去重机制

虽然 RabbitMQ 默认不提供重复消息过滤，但可以结合插件或 Stream 功能实现去重：

- **RabbitMQ Deduplication Plugin**：通过设置 `x-deduplication-header`，Broker 在 Exchange 或队列层面缓存 ID，并丢弃重复消息。
- **Streams 消息去重**（RabbitMQ 3.9+）：利用 producer name + sequence ID，实现 Broker 端跨重启且在窗口内滤重。

这两种方案可在消息进入队列前拦截重复，提高系统效率。

B

### 3. 消费者端：幂等处理 + 外部去重存储

消费者必须具备识别重复的能力，通常通过以下方式：

**三步走去重流程**：

1. 消息包含唯一 ID；
2. 拉出消息后，先检查该 ID 是否已存在“已处理”记录；
3. 如果不是，处理消息后再写入记录；否则跳过。

去重记录可以存储在：

- **数据库**（使用唯一键，如订单号）；
- **Redis** （设置 `SETNX` 或 `expired key` 实现快速去重）。

此外保持操作的幂等性（如使用乐观锁、状态检查等）进一步增强防重能力。
