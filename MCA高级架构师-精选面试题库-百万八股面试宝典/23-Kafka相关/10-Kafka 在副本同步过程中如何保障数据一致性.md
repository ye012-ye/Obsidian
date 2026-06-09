Kafka 在副本同步中通过 LEO、HW、ISR 和日志截断机制等关键步骤，确保数据在 leader 和 followers 之间的一致性：

M

### 1. 定义关键指标

- **LEO（Log End Offset）**：每个副本日志末尾的下一个消息偏移量。代表该副本已写入消息的总数+1。
- **HW（High Watermark）**：ISR 中所有副本的最小 LEO。只有 ≤ HW 的消息被视为“已提交”，消费者只能读取到该偏移之前的数据。

### 2. 正常同步流程

- leader 写入消息到本地 `.log`，并记录新的 LEO。
- followers 通过 Fetch 拉取日志并写入本地，同时更新各自的 LEO 和 HW（在下一个同步周期）。
- 当 ISR 中所有副本的 LEO ≥ 某消息偏移时，leader 将 HW 更新至该偏移，然后根据 `acks=all` 向生产者返回确认。

S

### 3. follower 落后与恢复

- 若 follower 长时间不 Pull，或 LEO 落后超过 `replica.lag.time.max.ms`，会被移出 ISR，但不影响写入。
- 恢复后，它会截断本地日志，将所有 LEO > last HW 的部分删除，从 HW 开始重新拉取同步，直至追平，然后重新加入 ISR。

### 4. leader 故障与日志安全

- 当 leader 挂掉，由 Controller 在 ISR 中选举新的 leader（默认不允许非 ISR 成为 leader，除非设置 `unclean.leader.election.enable=true`）。
- 新 leader 的 HW 可能低于前 leader 的 HW。此时，其他 followers 会截断日志到该新 leader 的 HW，以保持一致性。
- 之后继续拉取，同步日志，恢复正常。旧 leader 重新上线后也按此流程恢复为 follower。

B

### 5. 一致性保障总结

- **ISR 保证**：仅从同步副本中选 leader，确保“已提交”数据不丢失。
- **日志截断机制**：新 leader 崛起后，所有 followers 对应日志将截断至当前 HW，避免差异。
- **HW 控制消费范围**：消费者只能读取 HW 以内数据，确保数据一致性。
