---
title: Redis线程模型与IO多路复用
tags:
  - Redis
  - 线程模型
  - IO多路复用
  - epoll
  - 面试
created: 2026-04-07
up: "[[Redis底层原理 - 总览]]"
---

# Redis 线程模型与 IO 多路复用

这是 Redis 面试的**第一个问题**，几乎必问。

## Redis 为什么这么快

Redis 单机 QPS 可达 **10 万+**，核心原因：

```mermaid
graph TD
    A["Redis 为什么这么快？"]
    A --> B["1. 纯内存操作<br/>内存读写 ns 级 vs 磁盘 ms 级"]
    A --> C["2. 单线程<br/>无锁竞争、无上下文切换"]
    A --> D["3. IO 多路复用<br/>一个线程处理大量连接"]
    A --> E["4. 高效数据结构<br/>专门优化的底层实现"]
    A --> F["5. 通信协议简单<br/>RESP 协议解析高效"]
```

> [!important] 面试标准答案
> 1. **基于内存**，读写速度极快（ns 级别）
> 2. **单线程**模型，避免了多线程的锁竞争和上下文切换开销
> 3. 使用 **IO 多路复用**（epoll），单线程高效处理大量并发连接
> 4. **高效的数据结构**（SDS、ziplist、skiplist 等专门设计）
> 5. **RESP 协议**简单高效，解析成本低

---

## 单线程模型

### 什么是"单线程"？

> [!warning] 精确说法
> Redis 的**网络 IO 和命令执行**是单线程的。但 Redis **不是完全的单线程**程序。

Redis 有多个后台线程：
- **主线程**：处理网络 IO + 命令执行（核心，单线程）
- **bio_close_file**：异步关闭文件
- **bio_aof_fsync**：异步 AOF 刷盘
- **bio_lazy_free**：异步释放大对象内存（`UNLINK`、`FLUSHALL ASYNC`）

```mermaid
graph TD
    subgraph 主线程["主线程（单线程）"]
        A["接收客户端请求"] --> B["解析命令"]
        B --> C["执行命令"]
        C --> D["返回结果"]
    end
    
    subgraph 后台线程
        E["bio_close_file<br/>异步关闭文件"]
        F["bio_aof_fsync<br/>异步 AOF 刷盘"]
        G["bio_lazy_free<br/>异步释放内存"]
    end
    
    主线程 -.->|"委托耗时操作"| 后台线程
```

### 为什么用单线程？

1. **CPU 不是瓶颈**：Redis 操作基于内存，CPU 开销极小，瓶颈在**网络 IO 和内存**
2. **避免锁竞争**：多线程需要加锁保护共享数据，锁的开销可能超过并行带来的收益
3. **避免上下文切换**：线程切换需要保存/恢复寄存器等状态，有额外开销
4. **实现简单**：单线程代码更简单、更容易维护、bug 更少

---

## IO 多路复用

### 问题：单线程怎么处理大量并发连接？

答案是 **IO 多路复用**（I/O Multiplexing）。

### 传统 IO 模型对比

```mermaid
graph TD
    subgraph 阻塞IO["阻塞 IO（BIO）"]
        A1["线程1 ← 客户端1"] 
        A2["线程2 ← 客户端2"]
        A3["线程3 ← 客户端3"]
        A4["... 每个连接一个线程"]
    end
    
    subgraph 多路复用IO["IO 多路复用"]
        B1["客户端1"]
        B2["客户端2"]
        B3["客户端3"]
        B4["客户端N"]
        B1 & B2 & B3 & B4 --> C["epoll 内核监控<br/>哪些连接有数据可读"]
        C --> D["单线程逐个处理<br/>就绪的连接"]
    end
    
    style D fill:#a5d6a7
```

### select / poll / epoll 对比

| 特性 | select | poll | epoll |
|------|--------|------|-------|
| **连接数限制** | 1024（FD_SETSIZE） | 无限制 | 无限制 |
| **数据结构** | bitmap | 数组 | 红黑树 + 就绪链表 |
| **内核态遍历** | O(n) 全部遍历 | O(n) 全部遍历 | **O(1) 回调通知** |
| **用户态拷贝** | 每次全量拷贝 | 每次全量拷贝 | **不需要拷贝** |
| **触发方式** | 水平触发 LT | 水平触发 LT | LT + **边缘触发 ET** |

### epoll 工作原理

```mermaid
sequenceDiagram
    participant App as Redis 主线程
    participant Kernel as Linux 内核
    participant RBT as 红黑树（监控列表）
    participant RDL as 就绪链表

    App->>Kernel: epoll_create() 创建 epoll 实例
    App->>Kernel: epoll_ctl(ADD, fd1) 注册连接1
    App->>Kernel: epoll_ctl(ADD, fd2) 注册连接2
    Kernel->>RBT: 将 fd1, fd2 加入红黑树
    
    Note over Kernel: 当 fd1 有数据到达...
    Kernel->>RDL: 回调函数将 fd1 加入就绪链表
    
    App->>Kernel: epoll_wait() 阻塞等待
    Kernel-->>App: 返回就绪的 fd 列表 [fd1]
    
    App->>App: 处理 fd1 的请求
```

**epoll 的核心优势：**
1. **红黑树管理连接**：增删改查 O(log n)
2. **回调机制**：有事件时内核主动通知，不需要遍历所有连接
3. **就绪链表**：`epoll_wait()` 直接返回就绪的连接，O(1)
4. **mmap 共享内存**：内核和用户空间共享就绪列表，减少拷贝

---

## Redis 事件驱动模型

Redis 基于 **Reactor 模式**，封装了一套事件处理框架（ae 库）：

```mermaid
graph TD
    subgraph ae事件循环["ae 事件循环（Event Loop）"]
        A["aeMain()"]
        A --> B["aeProcessEvents()"]
        B --> C["IO 多路复用等待事件"]
        C --> D{"事件类型？"}
        D -->|"连接事件"| E["acceptTcpHandler<br/>接受新连接"]
        D -->|"读事件"| F["readQueryFromClient<br/>读取命令"]
        D -->|"写事件"| G["sendReplyToClient<br/>发送响应"]
        
        F --> H["processCommand<br/>执行命令"]
        H --> G
        
        G --> B
        E --> B
    end
    
    I["时间事件"] -.-> B
    I --> I1["serverCron<br/>（过期清理、持久化等）"]
```

### 文件事件 vs 时间事件

| 事件类型 | 说明 | 示例 |
|----------|------|------|
| **文件事件（File Event）** | 网络 IO 事件 | 新连接、读命令、写响应 |
| **时间事件（Time Event）** | 定时任务 | `serverCron`（默认 100ms 一次） |

**serverCron 做什么？**
- 清理过期 key
- 触发 RDB/AOF 持久化
- 主从复制心跳
- 集群节点状态检测
- 统计信息更新

---

## Redis 6.0 多线程

### 为什么引入多线程？

Redis 性能瓶颈已经从 CPU 转移到**网络 IO**：
- 网络数据的**读取和解析**消耗大量 CPU
- 响应数据的**序列化和发送**也消耗 CPU
- 而命令执行本身很快

```mermaid
graph LR
    subgraph "Redis 6.0 之前"
        A1["读请求"] --> B1["执行命令"] --> C1["写响应"]
        style A1 fill:#ffcdd2
        style C1 fill:#ffcdd2
        style B1 fill:#a5d6a7
    end
```

```
红色 = 网络IO（耗时大）  绿色 = 命令执行（很快）
```

### 多线程 IO 架构

```mermaid
sequenceDiagram
    participant C as 客户端
    participant IOT as IO 线程池
    participant Main as 主线程

    C->>IOT: 1. 多个 IO 线程并行读取请求数据
    Note over IOT: 读取 + 解析命令（多线程）
    
    IOT->>Main: 2. 将解析好的命令交给主线程
    Note over Main: 执行命令（仍然单线程！）
    
    Main->>IOT: 3. 将响应数据交给 IO 线程
    Note over IOT: 序列化 + 发送响应（多线程）
    
    IOT->>C: 4. 返回结果
```

```mermaid
graph TD
    subgraph "Redis 6.0 多线程模型"
        subgraph IO线程["IO 线程（多线程）"]
            T1["IO Thread 1<br/>读/写"]
            T2["IO Thread 2<br/>读/写"]
            T3["IO Thread 3<br/>读/写"]
            T4["IO Thread N<br/>读/写"]
        end
        
        subgraph 主线程["主线程（单线程）"]
            M["命令执行<br/>（原子性保证）"]
        end
        
        T1 & T2 & T3 & T4 -->|"读完毕"| M
        M -->|"写任务分发"| T1 & T2 & T3 & T4
    end
```

### 关键点

- **命令执行仍然是单线程**！不需要加锁
- 只有**网络读写**改为多线程
- 默认**不开启**，需要配置：

```
# redis.conf
io-threads 4              # IO 线程数（建议 CPU 核数的一半）
io-threads-do-reads yes    # 开启多线程读
```

> [!important] 面试回答
> Redis 6.0 引入多线程是为了优化**网络 IO 性能**，命令执行仍然是单线程的，所以不需要考虑线程安全问题。多线程 IO 可以提升约 **1 倍**的吞吐量。

---

## 面试高频问题

### Q1：Redis 是单线程还是多线程？

**分版本回答：**
- Redis 6.0 之前：网络 IO + 命令执行 = 单线程（有后台线程处理 close、fsync、free）
- Redis 6.0+：网络 IO = 多线程，命令执行 = 仍然单线程

### Q2：Redis 单线程为什么还这么快？

基于内存 + IO 多路复用 + 高效数据结构 + 避免锁竞争和上下文切换。

### Q3：epoll 和 select 的区别？

1. select 有 1024 连接数限制，epoll 无限制
2. select 每次需要遍历所有连接 O(n)，epoll 回调通知 O(1)
3. select 每次需要用户态和内核态之间拷贝全部 fd，epoll 不需要
4. epoll 支持边缘触发（ET），效率更高

### Q4：什么操作会阻塞 Redis 主线程？

1. **大 Key 操作**：`DEL` 一个百万元素的 Hash/Set
2. **keys *** 命令：O(n) 遍历所有 key
3. **大量 key 同时过期**：集中过期清理
4. **AOF always 刷盘**：每个命令都 fsync
5. **RDB fork**：fork 子进程时父进程短暂阻塞
6. **大集合的聚合操作**：SUNION、SINTER 等

> 解决方案：使用 `UNLINK`（异步删除）代替 `DEL`，用 `SCAN` 代替 `KEYS`。
