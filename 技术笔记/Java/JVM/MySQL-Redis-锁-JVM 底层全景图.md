---
tags: [JVM, MySQL, Redis, 锁, 底层原理, 全景图]
created: 2026-04-08
---

# MySQL · Redis · 锁 · JVM 底层全景图

> **阅读指南**：本文用 **4 张核心架构图 + 6 张专题细节图** 串联四大知识域。  
> 记忆口诀贯穿全文，配合图形辅助回忆。

---

## 🧠 一、JVM 全景架构

> **记忆口诀**：「**堆栈方程计**」= 堆 + 栈 + 方法区 + 程序计数器

```mermaid
graph TB
    subgraph JVM["🏗️ JVM 运行时数据区"]
        direction TB
        
        subgraph THREAD_PRIVATE["线程私有"]
            PC["📍 程序计数器<br/>当前字节码行号指示器<br/>唯一不会OOM的区域"]
            
            subgraph STACK["📚 虚拟机栈 (每线程一个)"]
                SF1["栈帧 Frame"]
                SF2["栈帧 Frame"]
                SF3["栈帧 Frame (栈顶=当前方法)"]
            end
            
            NS["🔧 本地方法栈<br/>Native 方法服务"]
        end
        
        subgraph THREAD_SHARED["线程共享"]
            subgraph HEAP["🗄️ 堆 Heap (GC主战场)"]
                subgraph YOUNG["新生代 Young (1/3堆)"]
                    EDEN["Eden 区 (8/10)"]
                    S0["Survivor 0 (1/10)"]
                    S1["Survivor 1 (1/10)"]
                end
                OLD["老年代 Old (2/3堆)"]
            end
            
            subgraph META["📋 元空间 Metaspace (堆外/直接内存)"]
                KI["类信息 Class Metadata"]
                CP["运行时常量池"]
                SM["静态变量 (JDK7+移入堆)"]
            end
        end
    end

    style THREAD_PRIVATE fill:#e3f2fd,stroke:#1565c0
    style THREAD_SHARED fill:#fff3e0,stroke:#e65100
    style YOUNG fill:#e8f5e9,stroke:#2e7d32
    style OLD fill:#fce4ec,stroke:#c62828
```

### 1.1 栈帧结构 (每次方法调用创建一个)

```mermaid
graph LR
    subgraph FRAME["📦 栈帧 Stack Frame"]
        LV["📋 局部变量表<br/>· slot 为最小单位<br/>· this 占 slot[0](实例方法)<br/>· long/double 占 2 slot"]
        OS["📊 操作数栈<br/>· 方法执行的工作区<br/>· iadd: 弹出两个int相加压栈"]
        DL["🔗 动态链接<br/>· 指向运行时常量池<br/>  中该方法的引用<br/>· 支持多态(虚方法表)"]
        RA["↩️ 返回地址<br/>· 正常返回: 恢复上层PC<br/>· 异常返回: 查异常处理器表"]
    end
```

### 1.2 对象头 — 锁升级的物理基础

> **记忆口诀**：「**无偏轻重**」= 无锁 → 偏向锁 → 轻量级锁 → 重量级锁

```mermaid
graph TD
    subgraph OBJ_HEADER["🔩 对象头 Object Header (64位JVM)"]
        MW["Mark Word (64bit)<br/>─────────────────<br/>无锁: [hashcode:31|age:4|biased:0|01]<br/>偏向锁: [threadID:54|epoch:2|age:4|biased:1|01]<br/>轻量级锁: [LockRecord指针:62|00]<br/>重量级锁: [Monitor指针:62|10]<br/>GC标记: [空|11]"]
        KP["Klass Pointer (32bit 压缩)<br/>指向方法区中的类元数据"]
        AL["数组长度 (仅数组对象)"]
    end
    
    MW --> KP --> AL
```

### 1.3 GC 体系

> **记忆口诀**：「**标复整分**」= 标记-清除 / 复制 / 标记-整理 / 分代收集

```mermaid
graph TB
    subgraph GC_ROOTS["🌳 GC Roots (可达性分析起点)"]
        R1["栈帧中局部变量引用的对象"]
        R2["方法区静态变量引用"]
        R3["方法区常量引用"]
        R4["Native方法引用"]
        R5["synchronized持有的对象"]
    end
    
    subgraph GC_ALGO["⚙️ 收集算法"]
        MC["标记-清除<br/>缺点: 内存碎片"]
        CP["复制算法<br/>Eden→S0/S1<br/>缺点: 浪费空间"]
        MCO["标记-整理<br/>移动存活对象<br/>缺点: STW较长"]
    end
    
    subgraph COLLECTORS["🚀 收集器演进"]
        direction LR
        CMS["CMS<br/>初始标记→并发标记<br/>→重新标记→并发清除<br/>⚠️碎片问题"]
        G1["G1 (JDK9默认)<br/>Region分区(1-32MB)<br/>Mixed GC<br/>可预测停顿"]
        ZGC["ZGC (JDK15+)<br/>着色指针+读屏障<br/>并发转移<br/>⏱️<10ms停顿"]
    end
    
    GC_ROOTS -->|"对象不可达"| GC_ALGO
    MC -->|"Old区使用"| CMS
    CP -->|"Young区使用"| G1
    CMS --> G1 --> ZGC
```

### 1.4 类加载机制

> **记忆口诀**：「**加验准解初**」= 加载 → 验证 → 准备 → 解析 → 初始化

```mermaid
graph LR
    subgraph CL["🔄 类加载过程"]
        L["加载 Loading<br/>读取.class字节流<br/>生成Class对象"] 
        V["验证 Verification<br/>魔数/版本/语义检查"]
        P["准备 Preparation<br/>static变量分配零值<br/>⚠️final常量直接赋值"]
        R["解析 Resolution<br/>符号引用→直接引用"]
        I["初始化 Init<br/>执行&lt;clinit&gt;<br/>static块+static赋值"]
    end
    L --> V --> P --> R --> I

    subgraph PARENTS["👨‍👦 双亲委派模型"]
        BC["Bootstrap ClassLoader<br/>rt.jar, java.lang.*"]
        EC["Extension ClassLoader<br/>ext/*.jar"]
        AC["Application ClassLoader<br/>classpath"]
        UC["自定义 ClassLoader<br/>打破双亲委派:<br/>Tomcat/OSGi/SPI"]
    end
    
    UC -->|"委派给父加载器"| AC -->|"委派"| EC -->|"委派"| BC
    BC -->|"找不到→向下"| EC -->|"找不到→向下"| AC -->|"找不到→向下"| UC
```

---

## 🗄️ 二、MySQL (InnoDB) 全景架构

> **记忆口诀**：「**缓改自日**」= Buffer Pool + Change Buffer + Adaptive Hash + Log Buffer

```mermaid
graph TB
    subgraph SERVER["MySQL Server 层"]
        CONN["连接器<br/>认证/权限/连接池"]
        CACHE["查询缓存 (8.0已删除)<br/>⚠️表任何写操作→缓存失效"]
        PARSER["解析器<br/>词法分析→语法树AST"]
        OPT["优化器<br/>· 选择索引<br/>· JOIN顺序<br/>· 成本模型CBO"]
        EXEC["执行器<br/>调用存储引擎接口"]
    end
    
    CONN --> CACHE --> PARSER --> OPT --> EXEC
    
    subgraph INNODB["🔥 InnoDB 存储引擎"]
        subgraph MEMORY["内存区域"]
            BP["📦 Buffer Pool (最核心!)<br/>· 数据页 + 索引页<br/>· LRU链表(young/old 5:3)<br/>· Free链表 + Flush链表<br/>· 默认128MB,建议60-80%内存"]
            CB["📝 Change Buffer<br/>· 缓存二级索引的DML<br/>· 非唯一索引写优化<br/>· merge时机: 读取/后台/关闭"]
            AHI["#️⃣ Adaptive Hash Index<br/>· InnoDB自动建立<br/>· 等值查询加速<br/>· 热点数据自动hash"]
            LB["📋 Log Buffer<br/>· redo log缓冲<br/>· 默认16MB"]
        end
        
        subgraph DISK["磁盘区域"]
            SYS["系统表空间 ibdata1"]
            FPT["独立表空间 .ibd<br/>(每表一个文件)"]
            REDO["♻️ Redo Log<br/>· 物理日志(页修改)<br/>· 循环写 (write pos / checkpoint)<br/>· WAL: 先写日志再写数据<br/>· innodb_flush_log_at_trx_commit"]
            UNDO["⏪ Undo Log<br/>· 逻辑日志(反向操作)<br/>· 事务回滚<br/>· MVCC版本链"]
            BINLOG["📜 Binlog (Server层)<br/>· 逻辑日志<br/>· 主从复制<br/>· 数据恢复<br/>· ROW/STATEMENT/MIXED"]
        end
    end
    
    EXEC --> BP
    BP <-->|"刷脏页"| FPT
    LB -->|"刷盘"| REDO
    BP -.->|"修改时写"| LB
    
    style MEMORY fill:#e8eaf6,stroke:#283593
    style DISK fill:#efebe9,stroke:#4e342e
```

### 2.1 B+树索引结构

> **记忆口诀**：「**聚二覆下**」= 聚簇索引 + 二级索引 + 覆盖索引 + 索引下推

```mermaid
graph TB
    subgraph CLUSTERED["🌲 聚簇索引 (主键索引)"]
        CR["根节点 [15|30]"]
        CM1["中间节点 [5|10|15]"]
        CM2["中间节点 [20|25|30]"]
        CL1["叶子节点<br/>key=5 → 整行数据<br/>key=10 → 整行数据"]
        CL2["叶子节点<br/>key=15 → 整行数据<br/>key=20 → 整行数据"]
        CL3["叶子节点<br/>key=25 → 整行数据<br/>key=30 → 整行数据"]
        
        CR --> CM1 & CM2
        CM1 --> CL1 & CL2
        CM2 --> CL2 & CL3
        CL1 <-->|"双向链表"| CL2 <-->|"双向链表"| CL3
    end
    
    subgraph SECONDARY["🌿 二级索引 (非主键索引)"]
        SR["根节点"]
        SL1["叶子节点<br/>name='Alice' → PK=5<br/>name='Bob' → PK=15"]
        SL2["叶子节点<br/>name='Carol' → PK=10"]
        
        SR --> SL1 & SL2
        SL1 -->|"🔙 回表查询<br/>拿PK去聚簇索引查完整行"| CR
    end

    style CLUSTERED fill:#e8f5e9,stroke:#2e7d32
    style SECONDARY fill:#fff3e0,stroke:#ef6c00
```

**索引优化三剑客：**

| 技术 | 原理 | 效果 |
|------|------|------|
| **覆盖索引** | 查询列全在索引中 | 避免回表，Using index |
| **索引下推 ICP** | WHERE条件在引擎层过滤 | 减少回表次数 |
| **最左前缀** | 联合索引`(a,b,c)`匹配最左列 | `a`✅ `a,b`✅ `b,c`❌ |

### 2.2 MVCC 多版本并发控制

> **记忆口诀**：「**版链视图四比较**」= Undo版本链 + Read View + 4个比较字段

```mermaid
graph TB
    subgraph ROW_VERSION["📜 Undo Log 版本链"]
        V3["当前版本<br/>trx_id=300<br/>name='Carol'<br/>roll_pointer↓"]
        V2["历史版本<br/>trx_id=200<br/>name='Bob'<br/>roll_pointer↓"]
        V1["历史版本<br/>trx_id=100<br/>name='Alice'<br/>roll_pointer=NULL"]
        
        V3 -->|"roll_pointer"| V2 -->|"roll_pointer"| V1
    end
    
    subgraph READ_VIEW["👁️ Read View (快照读时创建)"]
        RV["Read View 结构:<br/>━━━━━━━━━━━━━━━━━<br/>m_ids = [200, 300] (活跃事务ID列表)<br/>min_trx_id = 200 (最小活跃事务ID)<br/>max_trx_id = 301 (下一个待分配ID)<br/>creator_trx_id = 250 (创建者事务ID)"]
    end
    
    subgraph RULES["⚖️ 可见性判断规则"]
        R1["① trx_id == creator_trx_id → ✅ 可见 (自己改的)"]
        R2["② trx_id < min_trx_id → ✅ 可见 (已提交)"]
        R3["③ trx_id >= max_trx_id → ❌ 不可见 (未来事务)"]
        R4["④ min ≤ trx_id < max:<br/>   在m_ids中 → ❌ 不可见 (未提交)<br/>   不在m_ids中 → ✅ 可见 (已提交)"]
    end
    
    READ_VIEW --> RULES
    RULES -->|"不可见则沿版本链往下找"| ROW_VERSION

    style READ_VIEW fill:#e3f2fd,stroke:#1565c0
    style RULES fill:#fce4ec,stroke:#c62828
```

**隔离级别与 Read View：**

| 隔离级别 | Read View 创建时机 | 效果 |
|----------|-------------------|------|
| **READ COMMITTED** | 每次 SELECT 都创建新的 | 能读到其他事务已提交的 |
| **REPEATABLE READ** | 事务第一次 SELECT 时创建 | 整个事务看到同一快照 |

### 2.3 一条 UPDATE 的完整旅程

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server层
    participant E as InnoDB引擎
    participant BP as Buffer Pool
    participant UL as Undo Log
    participant RL as Redo Log
    participant BL as Binlog

    C->>S: UPDATE t SET name='X' WHERE id=1
    S->>E: 调用引擎接口
    E->>BP: 数据页在缓存中？
    BP-->>E: 不在→从磁盘加载到Buffer Pool
    E->>UL: ① 写Undo Log (记录旧值，支持回滚)
    E->>BP: ② 修改Buffer Pool中的数据页 (脏页)
    E->>RL: ③ 写Redo Log (prepare状态) ← WAL
    E-->>S: 引擎执行完成
    S->>BL: ④ 写Binlog
    S->>RL: ⑤ Redo Log 标记 commit ← 两阶段提交
    S-->>C: OK, 1 row affected
    
    Note over BP,RL: 脏页后续由后台线程异步刷盘
    Note over RL,BL: 两阶段提交保证 Redo Log 与 Binlog 一致
```

---

## 🔴 三、Redis 全景架构

> **记忆口诀**：「**单线复用，五型九底**」= 单线程 + IO多路复用 + 5种数据类型 + 9种底层编码

```mermaid
graph TB
    subgraph CLIENT["👥 客户端连接"]
        C1["Client 1"]
        C2["Client 2"]
        C3["Client N"]
    end
    
    subgraph REDIS["🔴 Redis 服务端"]
        subgraph IO_MODEL["📡 网络模型"]
            EPOLL["IO多路复用 (epoll/kqueue)<br/>· 单线程监听所有连接<br/>· 事件驱动，非阻塞<br/>· 6.0+: 多线程处理IO读写<br/>  (命令执行仍单线程!)"]
            
            subgraph EVENT_LOOP["⚡ 事件循环 (核心单线程)"]
                FE["文件事件<br/>客户端请求"]
                TE["时间事件<br/>定时任务/过期清理"]
            end
        end
        
        subgraph MEMORY["💾 内存数据"]
            subgraph DB["数据库 (默认16个 db0-db15)"]
                DICT["全局哈希表 dict<br/>key → redisObject"]
                EXP["过期字典 expires<br/>key → 过期时间戳"]
            end
            
            subgraph ROBJ["redisObject 结构"]
                TYPE_F["type: string/list/hash/set/zset"]
                ENC["encoding: 底层编码"]
                PTR["ptr: 指向实际数据结构"]
                LRU_F["lru: 最近访问时间"]
                REF["refcount: 引用计数"]
            end
        end
        
        subgraph PERSIST["💿 持久化"]
            RDB_P["RDB 快照<br/>· fork子进程 + COW<br/>· 二进制压缩文件<br/>· 恢复快,但可能丢数据"]
            AOF_P["AOF 追加日志<br/>· 记录每条写命令<br/>· always/everysec/no<br/>· AOF重写压缩"]
            MIX["混合持久化 (4.0+)<br/>RDB头 + AOF尾<br/>兼顾速度和安全"]
        end
    end
    
    C1 & C2 & C3 --> EPOLL
    EPOLL --> EVENT_LOOP
    FE --> DICT
    DICT --> ROBJ
    
    style IO_MODEL fill:#ffebee,stroke:#c62828
    style MEMORY fill:#e3f2fd,stroke:#1565c0
    style PERSIST fill:#e8f5e9,stroke:#2e7d32
```

### 3.1 数据类型与底层编码映射

> **记忆口诀**：「**字列哈集有，SDS快跳整哈**」

```mermaid
graph LR
    subgraph TYPES["5种数据类型"]
        STRING["String"]
        LIST["List"]
        HASH["Hash"]
        SET["Set"]
        ZSET["ZSet (Sorted Set)"]
    end
    
    subgraph ENCODINGS["底层数据结构"]
        INT_E["int<br/>8字节整数"]
        EMBSTR["embstr<br/>≤44字节连续内存"]
        RAW["raw (SDS)<br/>动态字符串"]
        
        ZIPLIST["ziplist 压缩列表<br/>连续内存,省空间<br/>级联更新问题"]
        LISTPACK["listpack (7.0+)<br/>替代ziplist<br/>无级联更新"]
        QUICKLIST["quicklist<br/>ziplist组成的双向链表"]
        
        SKIPLIST["skiplist 跳表<br/>多层链表,O(logN)查找<br/>层数随机(概率0.25)"]
        
        HASHTABLE["hashtable<br/>dict(两个ht)<br/>渐进式rehash"]
        
        INTSET_E["intset<br/>有序整数数组<br/>升级不降级"]
    end
    
    STRING --> INT_E & EMBSTR & RAW
    LIST --> QUICKLIST
    HASH --> LISTPACK & HASHTABLE
    SET --> INTSET_E & HASHTABLE
    ZSET --> LISTPACK & SKIPLIST

    style TYPES fill:#fff3e0,stroke:#e65100
    style ENCODINGS fill:#e8eaf6,stroke:#283593
```

### 3.2 Redis 为什么这么快？

```mermaid
graph TB
    FAST["🚀 Redis 为什么快?"]
    
    M1["① 纯内存操作<br/>内存读写 ~100ns<br/>磁盘随机读 ~10ms<br/>差10万倍"]
    M2["② 单线程无锁竞争<br/>避免上下文切换<br/>避免加锁开销<br/>原子性保证"]
    M3["③ IO多路复用<br/>一个线程监听N个socket<br/>epoll: O(1)事件通知"]
    M4["④ 高效数据结构<br/>专为场景优化<br/>SDS/跳表/压缩列表"]
    M5["⑤ 单线程执行命令<br/>6.0: 多线程仅处理IO<br/>命令执行仍串行"]
    
    FAST --> M1 & M2 & M3 & M4 & M5
```

### 3.3 内存淘汰策略

> **记忆口诀**：「**八策三维**」= 8种策略 × 全键/过期键/不淘汰 三个维度

| 策略 | 范围 | 算法 |
|------|------|------|
| `volatile-lru` | 有过期时间的key | 近似LRU |
| `volatile-lfu` | 有过期时间的key | LFU(访问频率) |
| `volatile-ttl` | 有过期时间的key | TTL最小的先淘汰 |
| `volatile-random` | 有过期时间的key | 随机 |
| `allkeys-lru` | 所有key | 近似LRU |
| `allkeys-lfu` | 所有key | LFU |
| `allkeys-random` | 所有key | 随机 |
| `noeviction` | — | 不淘汰，写操作返回OOM |

**过期删除策略**：惰性删除(访问时检查) + 定期删除(每100ms随机抽样检查)

---

## 🔒 四、锁的统一全景图 — JVM / MySQL / Redis

> **记忆口诀**：「**线事分**」= JVM线程级锁 → MySQL事务级锁 → Redis分布式锁

```mermaid
graph TB
    subgraph LOCK_UNIVERSE["🔒 锁的三个世界"]
        direction TB
        
        subgraph JVM_LOCK["🟦 JVM 锁 (单进程·线程间)"]
            direction TB
            SYNC["synchronized<br/>基于对象头 Mark Word"]
            RTL["ReentrantLock<br/>基于 AQS"]
            CAS_L["CAS 无锁<br/>Atomic* / LongAdder"]
        end
        
        subgraph MYSQL_LOCK["🟧 MySQL 锁 (单实例·事务间)"]
            direction TB
            GLOBAL["全局锁 FTWRL"]
            TABLE["表级锁<br/>表锁 / MDL元数据锁 / 意向锁"]
            ROW["行级锁<br/>记录锁 / 间隙锁 / 临键锁"]
        end
        
        subgraph REDIS_LOCK["🟥 Redis 锁 (分布式·进程间)"]
            direction TB
            SETNX["SETNX + EX<br/>单节点分布式锁"]
            REDLOCK["RedLock 算法<br/>多节点(N/2+1)"]
            REDISSON["Redisson<br/>看门狗自动续期"]
        end
    end
    
    JVM_LOCK -->|"跨JVM需要"| REDIS_LOCK
    MYSQL_LOCK -->|"跨数据库实例"| REDIS_LOCK
    
    style JVM_LOCK fill:#e3f2fd,stroke:#1565c0
    style MYSQL_LOCK fill:#fff3e0,stroke:#e65100
    style REDIS_LOCK fill:#ffebee,stroke:#c62828
```

### 4.1 JVM synchronized 锁升级全过程

> **核心**：锁升级不可逆（偏向锁→轻量级锁→重量级锁）

```mermaid
stateDiagram-v2
    [*] --> 无锁: 对象刚创建
    无锁 --> 偏向锁: 第一个线程访问<br/>CAS写入线程ID到Mark Word
    
    偏向锁 --> 偏向锁: 同一线程再次进入<br/>只需比较线程ID,无CAS
    偏向锁 --> 轻量级锁: 第二个线程竞争<br/>撤销偏向,到安全点暂停
    
    轻量级锁 --> 轻量级锁: CAS自旋获取<br/>拷贝Mark Word到Lock Record<br/>CAS替换Mark Word为指针
    轻量级锁 --> 重量级锁: 自旋超过阈值(自适应)<br/>或等待线程数>1
    
    重量级锁 --> 重量级锁: Monitor机制<br/>ObjectMonitor (C++)<br/>EntryList→Owner→WaitSet<br/>⚠️涉及用户态→内核态切换

    note right of 偏向锁
        适用: 只有一个线程访问
        开销: 几乎为零
        JDK15后默认关闭
    end note
    
    note right of 轻量级锁
        适用: 线程交替执行(无竞争)
        开销: CAS自旋,消耗CPU
    end note
    
    note right of 重量级锁
        适用: 多线程真正竞争
        开销: 系统调用,线程阻塞唤醒
        底层: pthread_mutex
    end note
```

### 4.2 AQS (AbstractQueuedSynchronizer)

> **ReentrantLock / Semaphore / CountDownLatch 的底层骨架**

```mermaid
graph TB
    subgraph AQS["🏛️ AQS 核心结构"]
        STATE["volatile int state<br/>━━━━━━━━━━━━━<br/>ReentrantLock: 0=无锁, ≥1=持有(可重入)<br/>Semaphore: 剩余许可数<br/>CountDownLatch: 剩余计数"]
        
        subgraph CLH["CLH 变体队列 (双向链表)"]
            HEAD["Head (哨兵节点)<br/>当前持有锁的线程"]
            N1["Node1<br/>thread=T1<br/>waitStatus=SIGNAL<br/>prev←→next"]
            N2["Node2<br/>thread=T2<br/>waitStatus=0"]
            
            HEAD <--> N1 <--> N2
        end
        
        OWNER["exclusiveOwnerThread<br/>当前持有锁的线程"]
    end
    
    subgraph FLOW["🔄 获取锁流程"]
        F1["① CAS尝试修改state"]
        F2["② 失败→包装成Node入队"]
        F3["③ 自旋+park等待"]
        F4["④ 前驱释放→unpark唤醒"]
        F5["⑤ CAS获取成功→出队"]
        
        F1 -->|"失败"| F2 --> F3 --> F4 --> F5
        F1 -->|"成功"| DONE["获取锁"]
    end
    
    subgraph FAIR["公平 vs 非公平"]
        FAIR_L["公平锁: 新线程必须排队<br/>hasQueuedPredecessors()"]
        UNFAIR_L["非公平锁(默认): 新线程先CAS抢<br/>失败再排队→吞吐量更高"]
    end
```

### 4.3 MySQL 行级锁详解

> **记忆口诀**：「**记间临**」= Record Lock + Gap Lock + Next-Key Lock

```mermaid
graph TB
    subgraph INDEX_LINE["索引记录线: ... 5 ... 10 ... 15 ... 20 ..."]
        direction LR
    end
    
    subgraph LOCK_TYPES["MySQL InnoDB 行锁三兄弟"]
        RL["🔴 Record Lock (记录锁)<br/>锁定单条索引记录<br/>SELECT ... FOR UPDATE WHERE id=10<br/>只锁 id=10 这一行"]
        
        GL["🟡 Gap Lock (间隙锁)<br/>锁定索引记录之间的间隙<br/>锁定 (5, 10) 之间的间隙<br/>防止其他事务INSERT<br/>⚠️ 只在RR级别存在"]
        
        NKL["🟢 Next-Key Lock (临键锁)<br/>= Record Lock + Gap Lock<br/>锁定 (5, 10] 左开右闭<br/>InnoDB默认加锁方式<br/>解决幻读问题"]
    end
    
    subgraph EXAMPLE["🔍 加锁规则 (重要!)"]
        E1["① 唯一索引等值查询<br/>命中 → 退化为Record Lock<br/>未命中 → 退化为Gap Lock"]
        E2["② 唯一索引范围查询<br/>Next-Key Lock"]
        E3["③ 非唯一索引等值查询<br/>命中 → Next-Key Lock + Gap Lock<br/>未命中 → Gap Lock"]
        E4["④ 无索引 → 锁全表!<br/>⚠️ 最危险的情况"]
    end
    
    style RL fill:#ffebee,stroke:#c62828
    style GL fill:#fff8e1,stroke:#f57f17
    style NKL fill:#e8f5e9,stroke:#2e7d32
```

### 4.4 Redis 分布式锁演进

```mermaid
graph TB
    subgraph V1["V1: 基础版 SETNX"]
        V1C["SET lock_key unique_id NX EX 30<br/>━━━━━━━━━━━━━━━━━<br/>NX: 不存在才设置<br/>EX: 过期时间防死锁<br/>unique_id: 防止误删别人的锁"]
        V1P["⚠️ 问题:<br/>1. 过期时间不好估算<br/>2. 业务没执行完锁就过期了<br/>3. 主从切换锁丢失"]
    end
    
    subgraph V2["V2: Redisson 看门狗"]
        V2C["✅ Watch Dog 机制<br/>━━━━━━━━━━━━━━━━━<br/>1. 默认加锁30s<br/>2. 后台线程每10s(1/3过期时间)续期<br/>3. 业务完成→取消续期→删除锁<br/>4. 宕机→不续期→自动过期"]
        V2F["流程:<br/>lock() → Lua脚本原子加锁<br/>→ 启动watchdog定时续期<br/>→ 业务执行<br/>→ unlock() → Lua脚本原子解锁"]
    end
    
    subgraph V3["V3: RedLock (多节点)"]
        V3C["🔐 RedLock 算法<br/>━━━━━━━━━━━━━━━━━<br/>N个独立Redis节点(建议5个)<br/>1. 记录开始时间T1<br/>2. 依次向N个节点加锁<br/>3. 超过N/2+1个成功 且<br/>   总耗时 < 锁过期时间<br/>   → 加锁成功<br/>4. 否则向所有节点解锁"]
        V3P["⚠️ Martin Kleppmann争议:<br/>· GC暂停/时钟跳跃可能导致不安全<br/>· 如需强一致→用ZooKeeper/etcd"]
    end
    
    V1 -->|"过期时间问题"| V2
    V2 -->|"主从切换问题"| V3
    
    style V1 fill:#ffebee,stroke:#c62828
    style V2 fill:#e8f5e9,stroke:#2e7d32
    style V3 fill:#e3f2fd,stroke:#1565c0
```

### 4.5 Redis 删除锁为什么要用 Lua?

```lua
-- 原子性: 判断+删除 在一个Lua脚本中执行
-- 防止: 判断是自己的锁 → 此时锁过期 → 别人加了新锁 → 删了别人的锁
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
else
    return 0
end
```

---

## 🎯 五、横向对比总结

### 5.1 锁的对比表

| 维度 | JVM synchronized | JVM ReentrantLock | MySQL 行锁 | Redis 分布式锁 |
|------|-----------------|-------------------|-----------|---------------|
| **粒度** | 对象/类 | 自定义 | 行/间隙 | key |
| **范围** | 单JVM进程 | 单JVM进程 | 单MySQL实例 | 跨进程跨机器 |
| **实现** | Monitor(C++) | AQS(Java) | Lock Manager | SETNX+Lua |
| **可重入** | ✅ 计数器 | ✅ state计数 | ✅ 同事务 | ✅ Redisson hash |
| **公平性** | ❌ 非公平 | ✅ 可选 | ❌ | ❌ |
| **死锁处理** | JVM不处理 | tryLock超时 | 死锁检测回滚 | 过期时间兜底 |
| **性能** | 偏向锁极快 | 略慢于sync | 依赖索引 | 网络RTT开销 |

### 5.2 三者协作场景

```mermaid
graph LR
    subgraph APP["应用服务器集群"]
        JVM1["JVM-1<br/>synchronized保护<br/>本地缓存操作"]
        JVM2["JVM-2<br/>ReentrantLock保护<br/>本地缓存操作"]
    end
    
    subgraph REDIS_CLUSTER["Redis"]
        DL["分布式锁<br/>SET lock NX EX<br/>跨JVM互斥"]
    end
    
    subgraph MYSQL_DB["MySQL"]
        ML["行锁 + MVCC<br/>SELECT ... FOR UPDATE<br/>数据一致性"]
    end
    
    JVM1 -->|"① JVM内: synchronized"| JVM1
    JVM1 & JVM2 -->|"② 跨JVM: Redis锁"| DL
    DL -->|"③ 获取锁后操作DB"| ML
    
    style APP fill:#e3f2fd,stroke:#1565c0
    style REDIS_CLUSTER fill:#ffebee,stroke:#c62828
    style MYSQL_DB fill:#fff3e0,stroke:#e65100
```

---

## 📝 记忆速查卡

| 主题 | 口诀 | 含义 |
|------|------|------|
| JVM内存 | **堆栈方程计** | 堆、栈、方法区、程序计数器 |
| GC算法 | **标复整分** | 标记清除、复制、标记整理、分代 |
| 类加载 | **加验准解初** | 加载→验证→准备→解析→初始化 |
| 锁升级 | **无偏轻重** | 无锁→偏向→轻量级→重量级 |
| InnoDB | **缓改自日** | Buffer Pool、Change Buffer、Adaptive Hash、Log Buffer |
| 索引 | **聚二覆下** | 聚簇、二级、覆盖、索引下推 |
| MVCC | **版链视图四比较** | Undo版本链 + ReadView 4字段判断 |
| 行锁 | **记间临** | Record Lock、Gap Lock、Next-Key Lock |
| Redis | **单线复用五型九底** | 单线程+IO复用, 5种类型9种编码 |
| 淘汰 | **八策三维** | 8种策略: LRU/LFU/TTL/Random × 全键/过期键 + noeviction |
| 分布式锁 | **设看红** | SETNX、看门狗、RedLock |
| 三层锁 | **线事分** | JVM线程锁→MySQL事务锁→Redis分布式锁 |

---

> 💡 **学习建议**：先看全景图建立框架 → 再深入每个专题图 → 最后用口诀反向回忆整张图
