Kafka 的存储模型基于 **Topic → Partition → Segment** 层级设计，支撑高吞吐与可靠性机制：

### 1. Topic 与 Partition

- Kafka 中一个 Topic 会被分为多个 Partition，每个 Partition 是一个有序的、不可变的消息日志。每条消息在 Partition 内由一个递增的 **offset** 标识，用于定位和消费。

M

### 2. Segment 文件切分机制

- 每个 Partition 物理存储在 Broker 的磁盘目录下，包含多个log segment 文件，而不是单个大日志文件。
- 每个 segment 文件组合包括 `.log`（消息内容）、`.index`（offset 到字节位置的映射）和 `.timeindex`（timestamp 到 offset 的映射）。
- Kafka 会基于配置的 `log.segment.bytes`（如默认 1 GB）或 `log.roll.ms` 自动切分，当满足大小或时间阈值时，新消息写入新的 segment，从而支持分段删除和读写并发。

### 3. `.log` 数据文件

- `.log` 文件采用 append‑only 方式顺序写入消息，并记录 batch 信息如 baseOffset、size、timestamp 等。
- 每写入一条或批量消息后，字节内容会被刷到磁盘，确保持久性。

S

### 4. `.index` 索引文件

- `.index` 文件记录 offset 与在 `.log` 中的物理位置映射，但为节省空间，它通常是稀疏索引，每隔固定字节量（由 `log.index.interval.bytes` 配置控制）插入一个映射条目。
- 消费者读取某 offset 时，先通过索引定位近似文件位置，再顺序查找消息内容，加快定位速度。

### 5. `.timeindex` 时间戳索引

- `.timeindex` 文件记录 timestamp 到 offset 的映射（如：T, offset），使得消费者可按时间（而非 offset）快速定位消息。

B
