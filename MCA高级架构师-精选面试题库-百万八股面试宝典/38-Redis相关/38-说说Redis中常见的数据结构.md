Redis 支持的不止是简单的 kv 存储——它提供丰富的数据结构来更高效地处理不同场景：M

### 1. 字符串（String）

- **定义**：二进制安全的字符串，可存储文本、数字，最大支持 512 MB。
- **命令**：`SET`、`GET`、`INCR`、`DECR`、`GETRANGE`、`SETBIT` 等。
- **适用场景**：缓存、计数器、Session、限流、分布式锁等。

### 2. 哈希（Hash）

- **定义**：字段–值结构，类似 Map/Dictonary，用于存储对象属性。
- **命令**：`HSET`、`HGET`、`HDEL`、`HINCRBY`、`HGETALL`、`HSCAN` 等。
- **适用场景**：用户资料缓存、多字段更新、计数统计、对象存取等。

### 3. 列表（List）

- **定义**：有序可重复字符串集合，可从两端插入/弹出元素。
- **命令**：`LPUSH`、`RPUSH`、`LPOP`、`RPOP`、`LRANGE`、`BLPOP`、`LTRIM` 等。
- **适用场景**：消息队列、任务队列、日志记录、栈/队列结构等。

### 4. 集合（Set）

- **定义**：无序且不重复的字符串集合。S
- **命令**：`SADD`、`SREM`、`SMEMBERS`、`SISMEMBER`、`SCARD`、`SINTER`、`SUNION`、`SRANDMEMBER` 等。
- **适用场景**：标签系统、去重、社交 graph 操作、随机抽选等。

### 5. 有序集合（Sorted Set，ZSET）

- **定义**：每个成员关联一个分数，成员唯一，但分数可重复，集合自动按分数排序。
- **命令**：`ZADD`、`ZRANGE`、`ZREM`、`ZINCRBY`、`ZRANGEBYSCORE`、`ZINTERSTORE` 等。
- **适用场景**：排行榜、延迟队列、限流滑动窗口、排序数据场景等。

B

## ​其他高级/特殊数据结构

(以下类型属于 Redis 7.0+ 或通过模块支持)

- **Bitmaps/Bitfields**：位级操作，适合同步标记、二值存储，如在线状态、功能开关。
- **HyperLogLog**：基于概率估算大量数据的唯一计数（基数）。
- **流（Streams）**：追加式日志场，支持消费者组，是消息队列、事件系统理想选择。
- **地理位置（Geo）**：经纬度索引与半径查询支持。
- **Probabilistic 结构**：Bloom Filter、Count‑min sketch、Top‑K、t‑digest 等适合大规模估算。
- **向量集（Vector Set）**：用于机器学习语义搜索。
- **时间序列（Time Series）**：专为时序数据设计的类型。
- **JSON**：通过 RedisJSON 模块支持，对 JSON 文档提供高效操作。
