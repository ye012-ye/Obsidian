RocketMQ 在 Broker 端通过严谨的存储架构设计与多项底层优化措施，实现了高吞吐、低延迟、高可靠的数据存储与查询能力。以下内容分模块说明。

M

### 一、存储模型架构

RocketMQ 的消息存储主要由三种文件组成：

- **CommitLog** 是所有消息的物理存储区，所有 Topic 的消息按顺序追加写入一个大日志文件中，默认每个文件大小为 1GB，并以起始物理偏移命名。这样确保了写操作的高性能和顺序性。
- **ConsumeQueue** 是逻辑消费队列文件，为每个 Topic + Queue 保存消息在 CommitLog 中的物理偏移、消息长度和 Tag 哈希值等信息，每条固定 20 字节，便于消费者快速定位消息。
- **IndexFile** 是用于按 Key 或时间区间快速查找消息的索引结构，单个 IndexFile 最大约 400MB，可支持数千万条索引。

存储结构实现了物理与逻辑分离，CommitLog 保存实际内容，ConsumeQueue 与 IndexFile 充当高效的索引路径。

S

### 二、底层优化策略

#### 顺序写入

RocketMQ 所有消息都以顺序方式写入 CommitLog，避免磁盘随机 I/O 带来的性能瓶颈，顺序写速度可达数百 MB/s。

#### 零拷贝机制

通过 Java NIO 的 `MappedByteBuffer` 将 CommitLog、ConsumeQueue 等映射至进程内存空间，减少系统调用和数据拷贝开销，显著提升读写效率。

#### 缓冲池与 PageCache 优化

开启 `transientStorePoolEnable` 后，RocketMQ 会首先将消息写入内存缓冲区（缓冲池），然后异步刷盘，降低 PageCache 锁竞争，提高并发写入吞吐。

### 三、文件管理与刷盘策略

#### 文件预分配机制

Broker 启动时会提前创建 CommitLog、ConsumeQueue、IndexFile 等文件，避免在写入过程中频繁扩容造成延迟波动。

#### 刷盘策略配置

提供两种刷盘模式：

- **SYNC\_FLUSH** 模式保证每次消息写入都立即落盘，适合对可靠性要求极高的场景；
- **ASYNC\_FLUSH** 模式则通过批量异步刷盘提升性能，稍有丢数据风险，适合对延迟敏感的高速写场景。

### 四、Tiered Storage 分级存储（RocketMQ 5.x 起）

RocketMQ 支持将冷数据迁移至对象存储系统（如 OSS、S3、MinIO），实现冷热数据分离与成本优化。上层访问统一通过 CommitLog、ConsumeQueue、IndexFile 结构，无需改变客户端逻辑。

该设计不仅支持灵活设置 Topic 的消息保存时长，还能避免冷数据读取影响热数据性能。

B

### 总结：

RocketMQ 的存储模型通过 CommitLog+ConsumeQueue+IndexFile 三层分离，实现高效写入与快速索引。结合顺序写、零拷贝、缓冲池机制与灵活刷盘策略，以及最新的分级存储插件，使它能够在海量消息场景中保持卓越性能与可靠性，无论是热数据处理还是冷数据归档都得以兼顾。
