RocketMQ 的消息存储体系由三大核心组件协作完成：**CommitLog（物理存储）**、**ConsumeQueue（消费索引）** 和 **IndexFile（业务 Key 索引）**，它们共同支持高效的写入、消费与查询流程。M

### 一、CommitLog — 顺序写入消息主体

Broker 接收到消息后，通过 mmap 映射将消息按顺序追加写入 CommitLog 文件中。每个 CommitLog 文件默认大小为 1GB，文件名以起始偏移量命名。该机制能最大化利用顺序 I/O，提升写入性能与吞吐量，实现高效持久化。

### 二、ConsumeQueue — 逻辑队列索引

每个 Topic 的每个 Queue 都对应一个 ConsumeQueue 文件，用于存储消息在 CommitLog 中的物理偏移、消息长度和 Tag Hash 值（共 20 字节）。每个 ConsumeQueue 文件支持约 30 万条记录，大小固定约为 5.7MB，对应逻辑消费队列。消费者查找消息时先访问 ConsumeQueue，获取偏移后从 CommitLog 中读取消息体。

### 三、IndexFile — 按 Key 或时间进行快速检索

可选启用的 IndexFile 用于消息追踪。它基于消息业务 Key 构建 Hash 索引，支持通过 Key 或时间区间查询消息偏移。每个 IndexFile 文件固定大小约为 400MB，可存放数千万条索引，底层结构类似 Java HashMap，采用槽位与链表（拉链法）解决冲突。

S

### 消息写入与索引构建流程

1. **写入阶段**：Broker 接收消息后调用 CommitLog.asyncPutMessage 将消息按序写入 CommitLog。
2. **异步索引**：后台线程 ReputMessageService 从 CommitLog 中读取新增消息，将其元数据写入对应 ConsumeQueue；若消息带 Key，还写入 IndexFile。
3. **消费阶段**：消费者依赖 ConsumeQueue 索引获取 CommitLog 偏移，从物理文件读取消息体。若启用索引功能，可按 Key 查询 IndexFile 检索偏移并结合 CommitLog 获取消息内容。

B

### 清理策略与存储管理

- **统一管理**：Broker 按存储时长或磁盘占用阈值自动清理过期消息，不依赖消费者是否消费。
- **目录结构清晰**：存储目录下包含 `commitlog/`, `consumequeue/{topic}/{queueId}/`, `index/`、`checkpoint`、`abort` 等辅助文件。清理机制确保旧数据统一淘汰，保证 Broker 稳定性。
