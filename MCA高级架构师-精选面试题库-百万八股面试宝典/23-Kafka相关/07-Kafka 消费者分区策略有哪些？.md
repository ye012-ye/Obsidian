Kafka 消费者组分区分配通过 `partition.assignment.strategy` 配置，支持 Range、RoundRobin、Sticky（含 CooperativeSticky）等几个主流策略，适用于不同需求。

### RangeAssignor（默认）

- **机制**：按主题对每个 topic 分区和消费者列表排序，依次按范围分配，余分区优先给第一个消费者。
- **优点**：保证同一 topic 不同 partition 的顺序消费，对多个 topic 顺序 join 有利。
- **缺点**：分区数 + 消费者数不均时，少数消费者压力大（“不均衡”场景）。

### RoundRobinAssignor

- **机制**：不分 topic，将所有分区平铺为一个列表，按消费者轮询分配。
- **优点**：跨 topic 分区分布更均衡，空闲消费者少，吞吐能力更高。
- **缺点**：若不同消费者订阅不同 topic，可能出现不均衡或资源浪费。

### StickyAssignor（粘性）

- **机制**：基于 RoundRobin 分配，但尽可能保留已有 assignment，减少重新分配部分，优先保持均衡。
- **优点**：稳定、减少 rebalance 引起的状态迁移与性能损失，对状态ful消费有利。
- **缺点**：严重变更时，仍需重新分配，但总体更温和。

### CooperativeStickyAssignor

- **机制**：在 Sticky 基础上使用协作式（incremental） rebalance，分两个阶段 revocation 与 assignment，可边消费边 rebalance。
- **优点**：最小化“停机”，即便重平衡时，仍能消费未撤销 partitions，适用于持续高吞吐操作中平滑扩缩容。
- **缺点**：要求所有消费者支持此协议，否则必须统一升级。

### 策略对比

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **策略** | **均衡性** | **顺序保障** | **重平衡开销** | **使用场景** |
| Range | 中等 | 高（每 topic 内） | 中 | 关注 topic 内顺序，topic 少消费者多 |
| RoundRobin | 好 | 中 | 较大 | 多 topic，均需并发，状态无关 |
| Sticky | 好 | 中 | 小 | 有状态处理，需降低 partition 跳动 |
| CooperativeSticky | 好 | 中 | 最小 | 高吞吐、低中断，逐步扩容优选 |
