---
title: Redis Sentinel与Cluster
tags:
  - Redis
  - Sentinel
  - Cluster
  - 高可用
  - 面试
created: 2026-04-07
up: "[[Redis底层原理 - 总览]]"
---

# Redis Sentinel 与 Cluster

## Redis Sentinel（哨兵）

### 架构

```mermaid
graph TD
    subgraph 哨兵集群["Sentinel 哨兵集群（至少3个）"]
        S1["Sentinel 1"]
        S2["Sentinel 2"]
        S3["Sentinel 3"]
    end
    
    S1 & S2 & S3 -.->|"监控"| M["Master"]
    S1 & S2 & S3 -.->|"监控"| SL1["Slave 1"]
    S1 & S2 & S3 -.->|"监控"| SL2["Slave 2"]
    
    M --> SL1
    M --> SL2
    
    S1 <-->|"通信"| S2
    S2 <-->|"通信"| S3
    S1 <-->|"通信"| S3
```

### Sentinel 核心功能

| 功能 | 说明 |
|------|------|
| **监控** | 持续检查主从节点是否正常运行 |
| **通知** | 通过 API 通知管理员或应用 |
| **自动故障转移** | 主节点下线时，自动将从节点提升为新主节点 |
| **配置中心** | 客户端连接 Sentinel 获取当前主节点地址 |

### 主观下线 vs 客观下线

```mermaid
sequenceDiagram
    participant S1 as Sentinel 1
    participant S2 as Sentinel 2
    participant S3 as Sentinel 3
    participant M as Master

    S1->>M: PING
    Note over M: 超过 down-after-milliseconds 无响应
    S1->>S1: 主观下线（SDOWN）

    S1->>S2: SENTINEL is-master-down-by-addr
    S1->>S3: SENTINEL is-master-down-by-addr
    
    S2-->>S1: 同意（也认为下线）
    S3-->>S1: 同意
    
    Note over S1: 超过 quorum 个 Sentinel 同意
    S1->>S1: 客观下线（ODOWN）
    
    Note over S1: 开始故障转移！
```

| 状态 | 条件 | 意义 |
|------|------|------|
| **主观下线（SDOWN）** | 单个 Sentinel 认为主节点不可达 | 可能是网络问题 |
| **客观下线（ODOWN）** | **quorum 个 Sentinel** 都认为主节点不可达 | 确认主节点真的挂了 |

### Sentinel Leader 选举

故障转移需要选出一个 Sentinel 来执行。使用 **Raft 算法**的 Leader 选举：

```mermaid
graph TD
    A["客观下线确认"] --> B["每个 Sentinel 向其他 Sentinel<br/>请求投票（先到先得）"]
    B --> C["获得多数票的 Sentinel<br/>成为 Leader"]
    C --> D["Leader 执行故障转移"]
```

### 故障转移流程

```mermaid
graph TD
    A["Sentinel Leader 开始故障转移"]
    A --> B["1. 选择新的主节点"]
    B --> B1["过滤不健康的从节点"]
    B1 --> B2["按优先级 priority 排序"]
    B2 --> B3["priority 相同，选复制偏移量最大的"]
    B3 --> B4["offset 相同，选 runid 最小的"]
    
    B4 --> C["2. 对选中的从节点执行 SLAVEOF NO ONE"]
    C --> D["3. 通知其他从节点 REPLICAOF 新主节点"]
    D --> E["4. 将旧主节点标记为新主节点的从节点<br/>（旧主恢复后自动成为从节点）"]
    E --> F["5. 通知客户端主节点已切换"]
```

**新主节点选择优先级：**
1. `replica-priority` 值最小的（0 表示永不参选）
2. 复制偏移量（offset）最大的（数据最完整）
3. runid 最小的

---

## Redis Cluster

### 为什么需要 Cluster？

| 架构 | 写入能力 | 存储容量 | 高可用 |
|------|----------|----------|--------|
| 单机 | 受限 | 受限 | ❌ |
| 主从 + Sentinel | 受限（单主） | 受限（单主） | ✅ |
| **Cluster** | **可扩展（多主）** | **可扩展（多主）** | ✅ |

### Cluster 架构

```mermaid
graph TD
    subgraph Cluster["Redis Cluster（至少6节点：3主3从）"]
        subgraph 分片1
            M1["Master 1<br/>Slots: 0-5460"]
            S1["Slave 1"]
            M1 --> S1
        end
        
        subgraph 分片2
            M2["Master 2<br/>Slots: 5461-10922"]
            S2["Slave 2"]
            M2 --> S2
        end
        
        subgraph 分片3
            M3["Master 3<br/>Slots: 10923-16383"]
            S3["Slave 3"]
            M3 --> S3
        end
    end
    
    M1 <-.->|"Gossip"| M2
    M2 <-.->|"Gossip"| M3
    M1 <-.->|"Gossip"| M3
```

### 数据分片：Hash Slot（哈希槽）

Redis Cluster 将数据划分为 **16384 个哈希槽**（0 ~ 16383），分配给各主节点。

```
slot = CRC16(key) % 16384
```

```mermaid
graph LR
    K["key = 'user:1'"]
    K --> CRC["CRC16('user:1') = 49154"]
    CRC --> MOD["49154 % 16384 = 386"]
    MOD --> SLOT["Slot 386 → Master 1"]
```

### 为什么是 16384 个槽？

> [!tip] Redis 作者的解释
> 1. 节点间 Gossip 协议交换位图（bitmap），16384 个槽 = 2KB，合理
> 2. 如果 65536 个槽 = 8KB，Gossip 消息太大
> 3. Redis Cluster 通常不超过 1000 个节点，16384 完全够用
> 4. 槽数是 2 的幂次，取模运算高效

### Hash Tag

```bash
# 默认情况，不同 key 可能分布在不同节点
SET user:1:name "Alice"    # slot X → Node A
SET user:1:age "25"        # slot Y → Node B（无法保证同节点）

# 使用 Hash Tag，用 {} 中的内容计算 slot
SET {user:1}:name "Alice"  # CRC16("user:1") → 同一个 slot
SET {user:1}:age "25"      # CRC16("user:1") → 同一个 slot ✅
```

### MOVED 和 ASK 重定向

```mermaid
sequenceDiagram
    participant C as 客户端
    participant N1 as Node 1
    participant N2 as Node 2

    C->>N1: GET key1
    Note over N1: slot 不在我这里
    N1-->>C: MOVED 3999 192.168.1.2:6379
    C->>C: 更新本地 slot 映射表
    C->>N2: GET key1
    N2-->>C: "value1"
```

| 重定向 | 含义 | 客户端行为 |
|--------|------|-----------|
| **MOVED** | slot 已永久迁移到其他节点 | 更新本地缓存，后续直接访问新节点 |
| **ASK** | slot 正在迁移中，临时重定向 | 只对当前请求重定向，不更新缓存 |

### Gossip 协议

节点间通过 Gossip 协议交换信息：

| 消息类型 | 说明 |
|----------|------|
| **PING** | 每秒随机选几个节点发送，携带自身状态 |
| **PONG** | 回复 PING，携带自身状态 |
| **MEET** | 邀请新节点加入集群 |
| **FAIL** | 广播某节点已被确认故障 |

```mermaid
graph TD
    A["Node A"] -->|"PING（携带已知节点信息）"| B["Node B"]
    B -->|"PONG（携带自身信息）"| A
    
    Note1["通过不断交换信息<br/>最终所有节点都知道<br/>集群的完整状态"]
    
    style Note1 fill:#fff9c4
```

### Cluster 故障转移

```mermaid
graph TD
    A["节点A 发现 Master X 无响应"]
    A --> B["标记为 PFAIL（疑似下线）"]
    B --> C["通过 Gossip 广播 PFAIL"]
    C --> D{"超过半数主节点<br/>都标记 PFAIL？"}
    D -->|"是"| E["标记为 FAIL（确认下线）"]
    E --> F["X 的从节点发起选举"]
    F --> G["获得多数主节点投票的从节点<br/>晋升为新主节点"]
    G --> H["接管 Master X 的 slots"]
    H --> I["广播新的 slot 映射"]
```

### 集群不可用的情况

| 场景 | 是否可用 |
|------|----------|
| 某个 slot 的主节点和所有从节点都挂了 | ❌ 默认不可用（`cluster-require-full-coverage yes`） |
| 超过半数主节点挂了 | ❌ 集群不可用 |
| 网络分区导致少数派无法通信 | ❌ 少数派不可用 |

---

## Sentinel vs Cluster 对比

| 特性 | Sentinel | Cluster |
|------|----------|---------|
| **数据分片** | ❌ 不支持 | ✅ 16384 个 hash slot |
| **写能力扩展** | ❌ 单主写入 | ✅ 多主并行写入 |
| **存储扩展** | ❌ 受限单机内存 | ✅ 多节点分摊 |
| **自动故障转移** | ✅ | ✅ |
| **复杂度** | 低 | 高 |
| **多 key 操作** | ✅ 无限制 | ⚠️ 必须同 slot |
| **适用场景** | 数据量不大，写压力不高 | 大数据量，高写入压力 |

---

## 面试高频问题

### Q1：Redis Cluster 的数据怎么分片？

使用 **Hash Slot**，共 16384 个槽。key 通过 `CRC16(key) % 16384` 计算槽号，每个主节点负责一部分槽。

### Q2：Sentinel 是怎么判断主节点下线的？

先**主观下线**（单个 Sentinel 认为不可达），再**客观下线**（超过 quorum 个 Sentinel 都认为不可达）。客观下线后 Sentinel 通过 Raft 选举 Leader，由 Leader 执行故障转移。

### Q3：Redis Cluster 为什么不用一致性哈希？

1. Hash Slot 方案更简单，容易理解和实现
2. 方便手动调整槽分配（数据迁移粒度更细）
3. 一致性哈希在节点变化时数据迁移量难以控制

### Q4：Cluster 模式下多 key 操作有什么限制？

多 key 操作（如 MGET、MSET、事务）要求所有 key 必须在同一个 slot。可以通过 Hash Tag `{tag}` 让相关 key 分配到同一个 slot。
