Kafka 使用**分区偏移量（offset）**来追踪消费者在每个 partition 中的消费进度，保障可靠性与可恢复性。以下是关键机制与实现方式：

### 偏移量基础

- 每条消息在 partition 中都有唯一的、递增的 offset 作为标识。消费者维护当前处理的位置（即下一条要读取消息的偏移），也会周期性地将**已处理的下一个 offset**提交到 Kafka 的内部主题 `__consumer_offsets`。M
- 这个提交的 offset 用于消费者重启或发生分组再平衡后恢复位置，防止重复处理或漏读。

### 自动 vs 手动提交

**自动提交（auto-commit）**

- 由 `enable.auto.commit=true` 控制，Kafka 会每 `auto.commit.interval.ms`（默认 5 秒）自动提交一次偏移。
- 简便但存在风险：消费者在提交和处理之间若崩溃，可能造成消息漏处理或重复消费。 S

**手动提交（manual commit）**

- 开发者关闭自动提交，调用 `commitSync()` 或 `commitAsync()` 完成偏移提交。

- `commitSync()` 阻塞直到确认提交，失败会重试，多用于确定时机提交。B
- `commitAsync()` 非阻塞，性能较高，但失败不会自动重试，可能被后续提交覆盖，需结合回调处理错误。

### 精准控制

- 可以通过传入 `Map<TopicPartition, OffsetAndMetadata>` 来手动提交具体 partition 的偏移，例如在批量处理完成后提交当前进度。
- 在消费者重平衡前后，可借助 `ConsumerRebalanceListener` 的 `onPartitionsRevoked` 和 `onPartitionsAssigned` 回调，确保撤销前完成偏移提交，分配后从正确位置恢复。

### 恢复与一致性保障

- 重启或分组再平衡时，消费者将从 `__consumer_offsets` 读取已提交的 offset 位置继续消费，保证消息顺序性与重复消费可控。
- 通过适当的提交策略结合 rebalance 监听，可以在性能与数据一致性之间灵活配置。
