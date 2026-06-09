Kafka 通过多层机制保障消息在全流程中的可靠性，覆盖 Producer、Broker、Consumer 三端：

M

### 1. Producer 端保障

- **acks 设置**：使用 `acks=all`（或 `-1`）表示生产者等待所有 ISR 副本确认后才认为消息写入成功。配合 `min.insync.replicas ≥ 2` 使用，对消息丢失提供最强保障。
- **重试与幂等**：设置 `retries > 0` 和 `enable.idempotence=true`。即使请求失败重试，也可避免消息重复，确保 exactly-once 语义。

S

### 2. Broker 端保障

- **顺序写入 & 异步刷盘**：消息 append 到磁盘日志，并在后台异步刷入 page cache，依赖 OS 批量 flush；即便 Broker 重启，也可由 ISR 副本恢复已提交消息。
- **Replication 副本机制**：主题分区至少设置 3 个副本（复制因子 ≥ 3），并配合 `min.insync.replicas=2` 和 `unclean.leader.election=false`，避免非同步副本成为 leader，从根本杜绝数据丢失。

B

### 3. Consumer 端保障

- **手动提交 offset**：关闭自动提交 (`enable.auto.commit=false`)，使用 `commitSync()` 或 `commitAsync()` 仅在消息被成功处理后提交偏移，避免消费失败导致消息丢失或重复。
- **消费容错设计**：消费者应实现幂等操作、使用 `isolation.level=read_committed`（对于事务消息），并设置 `auto.offset.reset=earliest` 以保证错过消息时可从最早开始消费。
