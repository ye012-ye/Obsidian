---
title: Redis缓存实战与经典问题
tags:
  - Redis
  - 缓存
  - 分布式锁
  - 双写一致
  - 面试
created: 2026-04-07
up: "[[Redis底层原理 - 总览]]"
---

# Redis 缓存实战与经典问题

本篇涵盖面试中 Redis 相关的**实战场景题**，是面试的重中之重。

## 缓存三大问题

### 全景图

```mermaid
graph TD
    A["缓存三大问题"]
    A --> B["缓存穿透<br/>查询不存在的数据"]
    A --> C["缓存击穿<br/>热点 key 过期"]
    A --> D["缓存雪崩<br/>大量 key 同时过期"]
    
    B --> B1["请求直达数据库"]
    C --> C1["瞬间大量请求打到数据库"]
    D --> D1["数据库瞬间压力暴增"]
    
    style B1 fill:#ffcdd2
    style C1 fill:#ffcdd2
    style D1 fill:#ffcdd2
```

---

### 缓存穿透

**定义**：查询的数据在**缓存和数据库中都不存在**，每次请求都直接打到数据库。

```mermaid
graph LR
    C["恶意请求<br/>id=-1"] --> CACHE{"Redis<br/>缓存未命中"}
    CACHE -->|"miss"| DB["MySQL<br/>也查不到"]
    DB -->|"null"| C
    
    Note["每次都穿透到数据库！"]
    style Note fill:#ffcdd2
```

**解决方案：**

| 方案 | 实现 | 优点 | 缺点 |
|------|------|------|------|
| **缓存空值** | 查不到时缓存 `null`，设短过期 | 简单 | 浪费内存、短暂不一致 |
| **布隆过滤器** | 请求前先过布隆过滤器 | 内存省、效率高 | 有误判率、不能删除 |
| **参数校验** | 接口层校验 id > 0 等 | 直接拦截 | 只能防简单攻击 |

#### 布隆过滤器

```mermaid
graph LR
    REQ["请求 id=xxx"] --> BF{"布隆过滤器<br/>数据是否可能存在？"}
    BF -->|"一定不存在"| REJECT["直接返回 ❌<br/>不查数据库"]
    BF -->|"可能存在"| CACHE["查 Redis"]
    CACHE -->|"miss"| DB["查 MySQL"]
    
    style REJECT fill:#a5d6a7
```

```
布隆过滤器原理：
1. 一个很长的 bit 数组 + 多个哈希函数
2. 添加元素：多个哈希函数计算位置，对应 bit 置为 1
3. 查询元素：所有位置都是 1 → 可能存在
              任何一个位置是 0 → 一定不存在

特点：
✅ 空间极小（1亿数据仅需约 120MB）
✅ 查询 O(k)，k 为哈希函数个数
❌ 有误判率（可能存在，但实际不存在）
❌ 不能删除元素（可以用 Counting Bloom Filter）
```

---

### 缓存击穿

**定义**：某个**热点 key 过期**的瞬间，大量并发请求同时涌入数据库。

```mermaid
graph TD
    A["热点 key 过期！"] --> B["1000个并发请求同时到来"]
    B --> C["缓存 miss"]
    C --> D["1000个请求全部打到数据库"]
    D --> E["💥 数据库崩溃"]
    
    style E fill:#ffcdd2
```

**解决方案：**

| 方案 | 说明 | 适用场景 |
|------|------|----------|
| **互斥锁** | 只有一个线程重建缓存，其他等待 | 一致性要求高 |
| **逻辑过期** | 不设 TTL，在 value 中存逻辑过期时间 | 可用性要求高 |
| **热点 key 永不过期** | 不设过期时间，手动更新 | 数据变化少 |

#### 互斥锁方案

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant T2 as 线程2
    participant R as Redis
    participant DB as MySQL

    T1->>R: GET key → null
    T1->>R: SETNX lock_key → 获取锁 ✅
    T1->>DB: 查询数据库
    
    T2->>R: GET key → null
    T2->>R: SETNX lock_key → 获取失败 ❌
    T2->>T2: sleep 重试...
    
    DB-->>T1: 返回数据
    T1->>R: SET key data（重建缓存）
    T1->>R: DEL lock_key（释放锁）
    
    T2->>R: GET key → 命中 ✅
```

#### 逻辑过期方案

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant T2 as 线程2
    participant R as Redis

    T1->>R: GET key
    Note over T1: 发现逻辑时间已过期
    T1->>R: SETNX lock_key（获取锁）
    T1->>T1: 开启新线程异步重建缓存
    T1-->>T1: 返回旧数据（不等待）
    
    T2->>R: GET key
    Note over T2: 也发现过期了
    T2->>R: SETNX lock_key → 获取失败
    T2-->>T2: 返回旧数据（不等待）
```

> 逻辑过期牺牲了短暂的一致性，换取高可用（不会等待）。

---

### 缓存雪崩

**定义**：**大量 key 同时过期**，或 **Redis 宕机**，导致请求全部打到数据库。

```mermaid
graph TD
    A["缓存雪崩原因"]
    A --> B["大量 key 同时过期"]
    A --> C["Redis 节点宕机"]
    
    B --> D["解决：过期时间加随机值"]
    C --> E["解决：Redis 高可用（Sentinel/Cluster）"]
    
    F["通用方案"]
    F --> F1["限流降级"]
    F --> F2["多级缓存（本地 + Redis）"]
    F --> F3["缓存预热"]
```

**解决方案汇总：**

| 问题原因 | 解决方案 |
|----------|----------|
| 大量 key 同时过期 | 过期时间加**随机偏移量**（如 base + random(0, 300)s） |
| Redis 宕机 | **Sentinel / Cluster** 高可用架构 |
| 通用 | **限流降级**（Hystrix / Sentinel） |
| 通用 | **多级缓存**（L1 本地缓存 + L2 Redis） |
| 通用 | **缓存预热**（提前加载热点数据） |

---

## 缓存与数据库双写一致性

### 问题本质

数据同时存在于 Redis 和 MySQL，更新数据时如何保证两者一致？

### 四种更新策略

| 策略 | 问题 |
|------|------|
| 先更新缓存，再更新数据库 | ❌ 数据库更新失败 → 缓存脏数据 |
| 先更新数据库，再更新缓存 | ❌ 并发时可能缓存旧值 |
| **先更新数据库，再删除缓存** ✅ | ⚠️ 极端场景有问题，但概率很低 |
| 先删除缓存，再更新数据库 | ❌ 并发时缓存旧值 |

### 推荐方案：Cache Aside Pattern（旁路缓存）

```
读：先读缓存 → 缓存未命中 → 读数据库 → 写入缓存
写：先更新数据库 → 再删除缓存
```

```mermaid
graph TD
    subgraph 读流程
        R1["读请求"] --> R2{"缓存命中？"}
        R2 -->|"命中"| R3["返回缓存数据"]
        R2 -->|"未命中"| R4["查数据库"]
        R4 --> R5["写入缓存"]
        R5 --> R3
    end
    
    subgraph 写流程
        W1["写请求"] --> W2["更新数据库"]
        W2 --> W3["删除缓存"]
    end
```

### 为什么是删除缓存而不是更新缓存？

```mermaid
sequenceDiagram
    participant A as 线程A
    participant B as 线程B
    participant Cache as Redis
    participant DB as MySQL

    Note over A,B: 场景：更新缓存导致的问题
    A->>DB: 更新为 value=10
    B->>DB: 更新为 value=20
    B->>Cache: 更新缓存 value=20
    A->>Cache: 更新缓存 value=10（覆盖了！）
    
    Note over Cache: 缓存 = 10，数据库 = 20 ❌
```

> 删除缓存是**幂等操作**，即使并发也不会产生错误值。下次读取时会重新加载最新数据。

### "先删缓存再更新数据库"的并发问题

```mermaid
sequenceDiagram
    participant A as 线程A（写）
    participant B as 线程B（读）
    participant Cache as Redis
    participant DB as MySQL

    A->>Cache: 1. 删除缓存
    B->>Cache: 2. 读缓存 → miss
    B->>DB: 3. 读数据库 → 旧值
    B->>Cache: 4. 将旧值写入缓存 ❌
    A->>DB: 5. 更新数据库为新值
    
    Note over Cache,DB: 缓存 = 旧值，数据库 = 新值 💥
```

### "先更新数据库再删缓存"的极端问题

```mermaid
sequenceDiagram
    participant A as 线程A（读）
    participant B as 线程B（写）
    participant Cache as Redis
    participant DB as MySQL

    Note over A: 缓存恰好过期
    A->>DB: 1. 读数据库 → 旧值
    B->>DB: 2. 更新数据库为新值
    B->>Cache: 3. 删除缓存
    A->>Cache: 4. 将旧值写入缓存 ❌
    
    Note over Cache,DB: 概率极低！因为读比写快得多<br/>步骤4几乎不可能在步骤3之后
```

> 这种情况**概率极低**（需要数据库读比写还慢），但为了极致一致性可以加延迟双删。

### 延迟双删

```python
# 写操作
def update(key, value):
    delete_cache(key)       # 1. 先删缓存
    update_db(key, value)   # 2. 更新数据库
    sleep(1)                # 3. 延迟一段时间（大于读请求耗时）
    delete_cache(key)       # 4. 再删缓存（删除可能的脏缓存）
```

### 更可靠的方案：基于消息队列

```mermaid
graph TD
    A["写请求"] --> B["更新数据库"]
    B --> C["发送删除消息到 MQ"]
    C --> D["消费者接收消息"]
    D --> E["删除缓存"]
    E --> F{"删除成功？"}
    F -->|"失败"| D
    F -->|"成功"| G["完成 ✅"]
```

### 最终方案：订阅 Binlog

```mermaid
graph LR
    A["写请求"] --> B["更新 MySQL"]
    B --> C["MySQL Binlog"]
    C --> D["Canal / Debezium<br/>监听 Binlog"]
    D --> E["删除/更新 Redis 缓存"]
```

> [!tip] 最佳实践
> 一般业务用 **Cache Aside（先更新 DB 再删缓存）** 就够了。
> 强一致场景用 **Canal 订阅 Binlog** 方案。

---

## 分布式锁

### 最基本的实现

```bash
# 加锁（原子操作）
SET lock_key unique_value NX PX 30000
# NX: 不存在才设置
# PX: 30秒过期（防止死锁）
# unique_value: 唯一标识（UUID），防止误删

# 释放锁（Lua 脚本保证原子性）
EVAL "if redis.call('GET',KEYS[1])==ARGV[1] then return redis.call('DEL',KEYS[1]) else return 0 end" 1 lock_key unique_value
```

### 为什么释放锁要用 Lua 脚本？

```mermaid
sequenceDiagram
    participant A as 线程A
    participant B as 线程B
    participant R as Redis

    A->>R: GET lock → "uuid-A"（是我的锁）
    Note over R: 此时锁恰好过期了！
    B->>R: SET lock "uuid-B" NX（B 获取了锁）
    A->>R: DEL lock（A 删了 B 的锁！💥）
    
    Note over A,B: 如果 GET + DEL 不是原子的<br/>就会误删别人的锁
```

### 分布式锁的完整要求

| 要求 | 实现方式 |
|------|----------|
| **互斥** | `SET NX` |
| **防死锁** | 设置过期时间 `PX` |
| **防误删** | value 存 UUID，释放时校验 |
| **可重入** | 用 Hash 存锁持有者 + 重入次数 |
| **自动续期** | 看门狗机制（Redisson） |

### Redisson 分布式锁

```mermaid
graph TD
    A["Redisson Lock"]
    A --> B["加锁：Lua 脚本<br/>HSET lock_key uuid:threadId 1"]
    A --> C["看门狗：后台线程<br/>每 10 秒续期到 30 秒"]
    A --> D["可重入：HINCRBY 计数"]
    A --> E["释放：HINCRBY -1<br/>计数为 0 时 DEL"]
```

### 看门狗机制

```mermaid
sequenceDiagram
    participant T as 业务线程
    participant W as 看门狗线程
    participant R as Redis

    T->>R: 加锁（默认 30s 过期）
    T->>T: 执行业务逻辑...
    
    loop 每 10 秒
        W->>R: 续期到 30 秒
    end
    
    T->>T: 业务完成
    T->>R: 释放锁
    T->>W: 停止看门狗
```

> 只有**不指定过期时间**时才启动看门狗。如果指定了过期时间，不启动看门狗。

### RedLock（红锁）—— 多节点分布式锁

```mermaid
graph TD
    A["RedLock 算法"]
    A --> B["部署 N 个独立的 Redis 节点（≥ 5）"]
    A --> C["依次向每个节点加锁"]
    A --> D["在多数节点（N/2 + 1）<br/>加锁成功 → 获取锁成功"]
    A --> E["加锁总耗时 < 锁过期时间"]
    A --> F["实际锁有效期 = 过期时间 - 加锁耗时"]
```

> [!warning] RedLock 争议
> Martin Kleppmann 认为 RedLock 在时钟跳跃等场景下不安全。对强一致有极高要求时，建议使用 **Zookeeper** 分布式锁。大多数场景单节点 Redis 锁 + Redisson 已足够。

---

## 热 Key 问题

### 识别热 Key

```bash
redis-cli --hotkeys             # Redis 4.0+（需 LFU 淘汰策略）
redis-cli MONITOR               # 实时监控（性能影响大，慎用）
# 或在应用层统计
```

### 解决方案

| 方案 | 说明 |
|------|------|
| **本地缓存** | L1 本地缓存（Caffeine/Guava）+ L2 Redis |
| **读写分离** | 热 key 分散到多个从节点读 |
| **Key 分片** | `hot_key_1`, `hot_key_2`...随机读取 |
| **热点发现 + 预加载** | 提前识别并加载到本地缓存 |

---

## 面试高频问题

### Q1：缓存穿透、击穿、雪崩的区别和解决方案？

| 问题 | 原因 | 核心方案 |
|------|------|----------|
| 穿透 | 查不存在的数据 | 布隆过滤器 + 缓存空值 |
| 击穿 | 热点 key 过期 | 互斥锁 / 逻辑过期 |
| 雪崩 | 大量 key 同时过期 | 随机过期 + 限流降级 |

### Q2：如何保证缓存和数据库的一致性？

推荐 **Cache Aside** 模式：读时加载缓存，写时先更新数据库再删除缓存。强一致场景用 Canal 订阅 Binlog。

### Q3：Redis 分布式锁怎么实现？需要注意什么？

`SET key value NX PX timeout`。注意：unique value 防误删、Lua 脚本释放锁、看门狗自动续期、Redisson 框架封装。

### Q4：为什么删除缓存而不是更新缓存？

1. 删除是幂等操作，并发安全
2. 更新缓存可能有并发覆盖问题（A 写 10，B 写 20，最终缓存可能是 10）
3. 缓存的计算成本可能高（不是简单的 DB 值），不一定每次更新都需要重新计算
