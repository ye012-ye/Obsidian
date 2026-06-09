---
title: Redis内存管理与过期淘汰
tags:
  - Redis
  - 内存管理
  - 过期策略
  - 淘汰策略
  - 面试
created: 2026-04-07
up: "[[Redis底层原理 - 总览]]"
---

# Redis 内存管理与过期淘汰

Redis 是内存数据库，内存管理直接影响性能和稳定性。

## 过期删除策略

给 key 设置过期时间后，Redis 怎么删除过期的 key？

```sql
SET name "Alice" EX 60      -- 60秒后过期
EXPIRE name 60               -- 给已有 key 设置过期时间
PEXPIRE name 60000           -- 毫秒级
EXPIREAT name 1735689600     -- 指定时间戳
```

### 三种过期删除策略

| 策略 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **定时删除** | 每个 key 一个定时器，到期立即删 | 内存友好 | CPU 不友好（大量定时器） |
| **惰性删除** | 访问 key 时才检查是否过期 | CPU 友好 | 内存不友好（可能大量过期key没被访问） |
| **定期删除** | 周期性随机抽查，删除过期 key | 折中 | 需要平衡频率和时长 |

> [!important] Redis 使用：惰性删除 + 定期删除

### 惰性删除

```mermaid
graph TD
    A["客户端访问 key"] --> B{"key 已过期？"}
    B -->|"是"| C["删除 key，返回 nil"]
    B -->|"否"| D["正常返回数据"]
```

### 定期删除（具体实现）

Redis 在 `serverCron` 中每秒执行 10 次（`hz = 10`）：

```mermaid
graph TD
    A["每 100ms 执行一次"] --> B["从设置了过期时间的 key 中<br/>随机抽取 20 个"]
    B --> C["删除其中已过期的 key"]
    C --> D{"过期 key 比例 > 25%？"}
    D -->|"是"| B
    D -->|"否"| E["结束本次检查"]
    
    F["每次执行上限 25ms<br/>（避免阻塞主线程）"]
    
    style F fill:#fff9c4
```

> [!warning] 大量 key 同时过期的问题
> 如果大量 key 在同一时刻过期，定期删除的循环可能接近 25ms 上限，造成**主线程阻塞**。
> **解决方案**：设置过期时间时加上**随机偏移量**：`EXPIRE key (base_time + random(0, 300))`

---

## 内存淘汰策略

当 Redis 使用内存达到 `maxmemory` 上限时，新的写入命令会触发**内存淘汰**。

### 8 种淘汰策略（Redis 4.0+）

```mermaid
graph TD
    A["内存达到上限<br/>触发淘汰"]
    
    A --> B["不淘汰"]
    B --> B1["noeviction ❌<br/>直接报错（默认！）"]
    
    A --> C["从所有 key 中淘汰"]
    C --> C1["allkeys-lru<br/>最近最少使用"]
    C --> C2["allkeys-lfu<br/>最不经常使用"]
    C --> C3["allkeys-random<br/>随机淘汰"]
    
    A --> D["从设置了过期时间的 key 中淘汰"]
    D --> D1["volatile-lru<br/>最近最少使用"]
    D --> D2["volatile-lfu<br/>最不经常使用"]
    D --> D3["volatile-random<br/>随机淘汰"]
    D --> D4["volatile-ttl<br/>最快过期的优先"]
```

| 策略 | 范围 | 算法 | 适用场景 |
|------|------|------|----------|
| **noeviction** | - | 不淘汰，报错 | 默认，不推荐 |
| **allkeys-lru** ✅ | 所有 key | LRU | **最常用**，缓存场景 |
| **allkeys-lfu** ✅ | 所有 key | LFU | 有热点数据的场景 |
| **allkeys-random** | 所有 key | 随机 | key 访问频率均匀 |
| **volatile-lru** | 有过期时间的 key | LRU | 部分 key 需要持久化 |
| **volatile-lfu** | 有过期时间的 key | LFU | 同上 |
| **volatile-random** | 有过期时间的 key | 随机 | 同上 |
| **volatile-ttl** | 有过期时间的 key | TTL 最小 | 优先淘汰快过期的 |

### LRU vs LFU

```mermaid
graph LR
    subgraph LRU["LRU（Least Recently Used）"]
        A["最近最少使用"]
        A --> A1["淘汰最久没有被访问的 key"]
        A --> A2["问题：偶尔访问一次的冷数据<br/>会被保留"]
    end
    
    subgraph LFU["LFU（Least Frequently Used）"]
        B["最不经常使用"]
        B --> B1["淘汰访问频率最低的 key"]
        B --> B2["优势：能识别真正的热点数据"]
    end
```

### Redis 的近似 LRU

Redis 没有实现精确的 LRU（需要额外链表，内存开销大），而是用**近似 LRU**：

```
每个 key 的 redisObject 中有 24 位 lru 字段（记录最后访问时间戳）

淘汰时：
1. 随机采样 N 个 key（默认 maxmemory-samples = 5）
2. 比较 lru 时间戳
3. 淘汰其中最久没有被访问的
```

> 采样数越大（如 10），越接近精确 LRU，但 CPU 开销越大。默认 5 已经很接近精确 LRU。

### Redis 的 LFU 实现

```
24 位 lru 字段拆分为两部分：

高 16 位: ldt (Last Decrement Time) - 上次衰减时间
低  8 位: logc (Logarithmic Counter) - 对数频率计数器（0-255）
```

**logc 的特点：**
- 不是线性增长，而是**对数增长**（概率性增加）
- 访问频率越高，增加概率越低
- 会**随时间衰减**（长时间不访问会降低）

```
访问时:
  counter_chance = 1.0 / (old_counter * lfu_log_factor + 1)
  if (random() < counter_chance) counter++
  
衰减:
  counter -= (当前时间 - ldt) * lfu_decay_time 分钟
```

> [!tip] 推荐配置
> 缓存场景推荐 **allkeys-lfu**（Redis 4.0+）或 **allkeys-lru**。

---

## 内存优化技巧

### 1. 使用合适的数据结构

```
# 100 万个用户信息

# ❌ 每个用户一个 String key（大量 key 开销）
SET user:1:name "Alice"
SET user:1:age "25"
# 每个 key 都有 redisObject(16B) + SDS + dictEntry 等开销

# ✅ 用 Hash 分桶存储（小 Hash 用 ziplist，内存紧凑）
# 将 user_id 分桶：user_id / 100 为 key，user_id % 100 为 field
HSET user:bucket:0 "1:name" "Alice"
HSET user:bucket:0 "1:age" "25"
```

### 2. 控制 key 的大小

```
# ❌ 长 key
SET user:information:detail:name:12345 "Alice"

# ✅ 短 key
SET u:12345:n "Alice"
```

### 3. 整数共享对象

Redis 启动时预建 0-9999 的整数对象，多个 key 共享。

```
SET a 100   → 引用共享的整数对象 100
SET b 100   → 引用同一个共享对象（refcount++）
```

> 开启 LRU/LFU 淘汰策略时，共享对象仍然生效。

### 4. 大 Key 治理

| 类型 | 大 Key 标准 | 问题 |
|------|-------------|------|
| String | > 10KB | 网络传输慢 |
| Hash/Set/Zset/List | > 5000 个元素 或 > 10MB | 操作阻塞 |

**排查大 Key：**
```bash
redis-cli --bigkeys             # 扫描大 key
redis-cli --memkeys             # 按内存排序
redis-cli MEMORY USAGE key_name # 查看单个 key 内存
```

**删除大 Key：**
```bash
# ❌ DEL bigkey → 阻塞主线程！
# ✅ UNLINK bigkey → 异步删除（后台线程处理）
# ✅ 分批删除（HSCAN + HDEL 每次删一部分）
```

---

## 面试高频问题

### Q1：Redis 的过期策略是什么？

惰性删除 + 定期删除。惰性删除是访问 key 时检查是否过期；定期删除是每秒 10 次随机抽查 20 个有过期时间的 key，删除已过期的。

### Q2：Redis 的内存淘汰策略有哪些？

8 种：noeviction、allkeys-lru、allkeys-lfu、allkeys-random、volatile-lru、volatile-lfu、volatile-random、volatile-ttl。推荐缓存场景用 allkeys-lru 或 allkeys-lfu。

### Q3：LRU 和 LFU 的区别？

LRU 淘汰最近最少**使用**的，LFU 淘汰最不**经常**使用的。LFU 更能识别热点数据，因为偶尔访问一次的冷数据在 LFU 下频率计数仍然很低。

### Q4：大量 key 同时过期会怎样？

可能导致主线程阻塞（定期删除循环执行接近上限时间）。解决方案：设置过期时间时加随机偏移量，避免集中过期。
