在 Kafka 中，Topic 是逻辑消息流的抽象，而 Partition 是 Topic 在物理上的划分单元，二者相互依存，支撑 Kafka 的可扩展性与并发策略。

M

### 1. **Topic：逻辑组织单元**

- 代表一类消息的主题或通道，相当于应用中的“消息类别”或数据库中的“表”。
- 客户端通过 Producer 指定 Topic 发布消息，Consumer 通过订阅 Topic 接收消息。

S

### 2. **Partition：物理分片单位**

- 每个 Topic 被分割成若干 Partition，每个 Partition 是一个有序、不可变的日志序列，消息在内部按 offset 递增存储。
- Partition 是扩展与并发的基础：可以跨 broker 分布、并允许多个 consumer 并行处理不同 partition。

B

### ​**二者之间的关系**

- **一对多**：一个 Topic 对应多个 Partition，每增加一个 Partition，Topic 的并发消费和吞吐能力随之提升。
- **顺序语义**：Kafka 保证单个 Partition 内的严格顺序，但不保证跨 Partition 的全局顺序。
- **并行处理**：Consumer group 中，每个 partition 被分配给一个 consumer 实例，实例与 partition 一一映射，若 consumer 数多于 partition，则多余者闲置。
