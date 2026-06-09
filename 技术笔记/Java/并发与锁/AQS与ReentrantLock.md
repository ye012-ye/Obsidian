---
title: AQS与ReentrantLock
tags:
  - Java
  - AQS
  - ReentrantLock
  - 面试
created: 2026-04-07
up: "[[Java并发与锁底层原理 - 总览]]"
---

# AQS 与 ReentrantLock

AQS 是 Java 并发包的**灵魂框架**，ReentrantLock、Semaphore、CountDownLatch 等都基于它实现。

## AQS 核心原理

### AQS 是什么？

**AbstractQueuedSynchronizer**（抽象队列同步器），Doug Lea 大师的杰作。

```mermaid
graph TD
    A["AQS 抽象队列同步器"]
    A --> B["核心1: state 状态变量<br/>volatile int state"]
    A --> C["核心2: CLH 双向队列<br/>等待获取锁的线程队列"]
    A --> D["核心3: CAS + 自旋<br/>线程安全地修改 state"]
    
    E["基于 AQS 的实现"]
    E --> E1["ReentrantLock"]
    E --> E2["ReentrantReadWriteLock"]
    E --> E3["Semaphore"]
    E --> E4["CountDownLatch"]
    E --> E5["CyclicBarrier"]
```

### AQS 核心结构

```mermaid
graph TD
    subgraph AQS
        STATE["volatile int state = 0<br/>━━━━━━━━━━━<br/>0 = 锁空闲<br/>1 = 锁被持有<br/>>1 = 重入次数"]
        
        OWNER["Thread exclusiveOwnerThread<br/>当前持有锁的线程"]
        
        subgraph CLH队列["CLH 双向等待队列"]
            HEAD["HEAD<br/>(哨兵节点)"]
            N1["Node<br/>Thread-B<br/>waitStatus=-1"]
            N2["Node<br/>Thread-C<br/>waitStatus=-1"]
            N3["Node<br/>Thread-D<br/>waitStatus=0"]
            TAIL["TAIL"]
            
            HEAD <--> N1 <--> N2 <--> N3
            TAIL --> N3
        end
    end
    
    style STATE fill:#e1bee7
    style CLH队列 fill:#e3f2fd
```

### Node 节点状态

| waitStatus | 值 | 含义 |
|------------|-----|------|
| **CANCELLED** | 1 | 线程已取消 |
| **SIGNAL** | -1 | 后继节点需要被唤醒 |
| **CONDITION** | -2 | 在 Condition 队列中等待 |
| **PROPAGATE** | -3 | 共享模式下传播唤醒 |
| **0** | 0 | 初始状态 |

---

## ReentrantLock 加锁流程（非公平锁）

这是面试**最核心**的流程，逐步拆解：

```mermaid
graph TD
    A["lock()"] --> B["尝试 CAS: state 0→1"]
    B --> C{"CAS 成功？"}
    C -->|"成功"| D["获取锁 ✅<br/>exclusiveOwnerThread = 当前线程"]
    C -->|"失败"| E["acquire(1)"]
    
    E --> F["tryAcquire(1)"]
    F --> G{"state == 0？<br/>（锁空闲）"}
    G -->|"是"| H["CAS: state 0→1"]
    H --> I{"CAS 成功？"}
    I -->|"成功"| D
    I -->|"失败"| J["加入 CLH 队列"]
    
    G -->|"否（锁被占）"| K{"是当前线程？<br/>（重入检查）"}
    K -->|"是"| L["state += 1 (重入) ✅"]
    K -->|"否"| J
    
    J --> M["acquireQueued()"]
    M --> N["自旋检查前驱是否为 HEAD"]
    N --> O{"前驱是 HEAD？"}
    O -->|"是"| P["再次 tryAcquire"]
    P --> Q{"成功？"}
    Q -->|"成功"| R["出队，获取锁 ✅"]
    Q -->|"失败"| S["park() 阻塞当前线程 😴"]
    O -->|"否"| S
    S -->|"被唤醒"| N
    
    style D fill:#a5d6a7
    style L fill:#a5d6a7
    style R fill:#a5d6a7
    style S fill:#ffcdd2
```

### 入队过程图解

```mermaid
sequenceDiagram
    participant A as 线程A（持有锁）
    participant B as 线程B（等待）
    participant C as 线程C（等待）
    participant Q as CLH Queue

    Note over A: state=1, owner=A
    
    B->>Q: CAS 失败，加入队列
    Note over Q: HEAD ↔ B(SIGNAL) → TAIL
    B->>B: park() 阻塞 😴
    
    C->>Q: CAS 失败，加入队列
    Note over Q: HEAD ↔ B(SIGNAL) ↔ C(0) → TAIL
    C->>C: park() 阻塞 😴
    
    A->>A: unlock() → state=0
    A->>Q: 唤醒 HEAD 的后继节点 B
    B->>B: unpark() 被唤醒
    B->>B: tryAcquire() → state=1, owner=B ✅
    Note over Q: HEAD=B ↔ C(SIGNAL) → TAIL
```

---

## ReentrantLock 解锁流程

```mermaid
graph TD
    A["unlock()"] --> B["tryRelease(1)"]
    B --> C["state -= 1"]
    C --> D{"state == 0？"}
    D -->|"否（还有重入）"| E["返回 false<br/>还没完全释放"]
    D -->|"是"| F["exclusiveOwnerThread = null<br/>锁完全释放"]
    F --> G{"CLH 队列有等待线程？"}
    G -->|"是"| H["unpark() 唤醒<br/>HEAD 的后继节点"]
    G -->|"否"| I["完成"]
    H --> I
    
    style F fill:#a5d6a7
```

---

## 公平锁 vs 非公平锁

```mermaid
graph TD
    subgraph 非公平锁["非公平锁（默认）"]
        NF1["新来的线程直接 CAS 抢锁"]
        NF1 -->|"成功"| NF2["直接获取 ✅<br/>（插队了！）"]
        NF1 -->|"失败"| NF3["加入 CLH 队列排队"]
    end
    
    subgraph 公平锁["公平锁"]
        F1["新来的线程先检查<br/>CLH 队列是否有人排队"]
        F1 --> F2{"队列有人？"}
        F2 -->|"有"| F3["乖乖排队<br/>加入 CLH 队列尾部"]
        F2 -->|"没有"| F4["CAS 获取锁"]
    end
```

### 源码区别（一行代码的差异！）

```java
// 非公平锁的 tryAcquire
if (state == 0) {
    if (compareAndSetState(0, 1)) {  // 直接 CAS 抢
        setExclusiveOwnerThread(current);
        return true;
    }
}

// 公平锁的 tryAcquire
if (state == 0) {
    if (!hasQueuedPredecessors() &&   // 先检查队列！多了这一行
        compareAndSetState(0, 1)) {
        setExclusiveOwnerThread(current);
        return true;
    }
}
```

### 对比

| 特性 | 非公平锁 | 公平锁 |
|------|----------|--------|
| **是否按顺序** | ❌ 新线程可以插队 | ✅ 严格 FIFO |
| **吞吐量** | **高**（减少上下文切换） | 低 |
| **饥饿** | 可能（某些线程一直抢不到） | ❌ 不会 |
| **默认** | ✅ 默认 | 需显式指定 |

```java
// 非公平锁（默认）
ReentrantLock lock = new ReentrantLock();
ReentrantLock lock = new ReentrantLock(false);

// 公平锁
ReentrantLock lock = new ReentrantLock(true);
```

> [!tip] 为什么默认非公平？
> 非公平锁性能更好。新来的线程直接获取锁，避免了唤醒队列中线程的**上下文切换**开销。在大部分场景下，吞吐量更重要。

---

## Condition 条件变量

Condition 是 synchronized 中 `wait/notify` 的升级版。

```mermaid
graph TD
    subgraph AQS
        CLH["CLH 等待队列<br/>（等待获取锁）<br/>Node-B → Node-C"]
        
        CQ1["Condition 队列1<br/>（等待某个条件）<br/>Node-D → Node-E"]
        
        CQ2["Condition 队列2<br/>（等待另一个条件）<br/>Node-F"]
    end
    
    A["线程调用 await()"] -->|"释放锁<br/>从 CLH 移到<br/>Condition 队列"| CQ1
    
    B["线程调用 signal()"] -->|"从 Condition 队列<br/>移回 CLH 队列<br/>等待重新获取锁"| CLH
```

```java
ReentrantLock lock = new ReentrantLock();
Condition notEmpty = lock.newCondition();
Condition notFull = lock.newCondition();

// 生产者
lock.lock();
try {
    while (queue.isFull()) {
        notFull.await();    // 等待"不满"条件
    }
    queue.add(item);
    notEmpty.signal();      // 通知"不空"条件
} finally {
    lock.unlock();
}

// 消费者
lock.lock();
try {
    while (queue.isEmpty()) {
        notEmpty.await();   // 等待"不空"条件
    }
    item = queue.poll();
    notFull.signal();       // 通知"不满"条件
} finally {
    lock.unlock();
}
```

### wait/notify vs await/signal

| 特性 | wait/notify | Condition await/signal |
|------|-------------|----------------------|
| **使用范围** | synchronized 中 | ReentrantLock 中 |
| **条件数量** | 只有一个等待队列 | **多个 Condition**（精确唤醒） |
| **响应中断** | 不支持 | ✅ `awaitUninterruptibly()` |
| **超时等待** | 支持 | ✅ `await(time, unit)` |

---

## synchronized vs ReentrantLock

```mermaid
graph TD
    subgraph synchronized
        S1["JVM 内置关键字"]
        S2["自动加锁/释放"]
        S3["不可中断"]
        S4["非公平锁"]
        S5["只有一个等待队列"]
        S6["JVM 自动优化<br/>（锁升级/消除/粗化）"]
    end
    
    subgraph ReentrantLock
        R1["Java API（java.util.concurrent）"]
        R2["手动 lock()/unlock()"]
        R3["可中断 lockInterruptibly()"]
        R4["公平/非公平可选"]
        R5["多个 Condition"]
        R6["tryLock() 尝试获取"]
    end
```

| 特性 | synchronized | ReentrantLock |
|------|-------------|---------------|
| **层面** | JVM 关键字 | Java API |
| **释放锁** | 自动（离开代码块） | **手动 unlock()**（必须 finally） |
| **可中断** | ❌ | ✅ `lockInterruptibly()` |
| **公平锁** | ❌ 只有非公平 | ✅ 可选公平/非公平 |
| **多条件** | ❌ 一个 wait set | ✅ 多个 Condition |
| **尝试获取** | ❌ | ✅ `tryLock()` |
| **性能** | JDK 6+ 优化后接近 | 接近 |
| **使用建议** | 优先使用（简单安全） | 需要高级功能时使用 |

---

## 面试高频问题

### Q1：AQS 的原理？

AQS 核心是一个 volatile int state（锁状态）和一个 CLH 双向等待队列。获取锁时 CAS 修改 state，失败则加入 CLH 队列阻塞等待。释放锁时将 state 置 0 并唤醒队列中的下一个线程。

### Q2：ReentrantLock 的加锁流程？

1. CAS 尝试将 state 从 0 改为 1
2. 成功则获取锁；失败则检查是否重入（当前线程持有则 state+1）
3. 都不是则加入 CLH 队列
4. 在队列中自旋检查前驱是否为 HEAD，是则再次尝试获取
5. 否则 park() 阻塞等待被唤醒

### Q3：公平锁和非公平锁的区别？

非公平锁新来的线程直接 CAS 抢锁，可能插队；公平锁先检查 CLH 队列是否有人排队。非公平锁吞吐量更高（减少上下文切换），但可能导致线程饥饿。

### Q4：synchronized 和 ReentrantLock 怎么选？

优先用 synchronized（简单、自动释放、JVM 优化）。需要可中断等待、公平锁、多条件、tryLock 等高级功能时用 ReentrantLock。
