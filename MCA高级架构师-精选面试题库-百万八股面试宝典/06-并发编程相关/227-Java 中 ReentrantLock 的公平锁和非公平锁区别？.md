在 Java 中，`ReentrantLock` 基于 `AbstractQueuedSynchronizer`（AQS）实现，并通过两种内部同步器来支持公平与非公平模式。M

#### 公平锁（FairSync 模式）

- 在调用构造器 `new ReentrantLock(true)` 时，内部使用 `FairSync` 实现。
- 当线程尝试获取锁时，如果队列中已有等待线程（`hasQueuedPredecessors()` 返回 true），新线程不会插队，而是加入 FIFO 等待队列。释放锁后，队首线程被唤醒并优先获取锁。此策略保证等待最久的线程优先获得锁，但在高并发下性能开销较大。S

#### 非公平锁（NonFairSync 模式）

- 默认构造器 `new ReentrantLock()` 使用 `NonfairSync`。
- 在尝试获取锁时，线程首先通过 CAS 尝试立即获取锁（`initialTryLock()`），即使有其他线程正在等待，也能“插队”获得锁。如果 CAS 失败，才加入等待队列。这种策略在低延迟场景下吞吐较高，但可能导致某些线程长期得不到锁。

#### 共同底层机制

- 两种模式都继承自 AQS 的 Sync 抽象类，共享相同的状态管理结构：使用 `state` 表示锁计数、`exclusiveOwnerThread` 表示锁持有线程，以及一个以 CLH 队列形式组织的等待链表（FIFO）。
- `lock()` 方法委托给 `sync.lock()`；`unlock()` 调用 `sync.release(1)`。释放时公平锁会唤醒队首线程，非公平锁则可能唤醒其他线程或插队线程。

B

### 对比：

|  |  |  |
| --- | --- | --- |
| **特性** | **公平锁（FairSync）** | **非公平锁（NonFairSync）** |
| 顺序策略 | 严格 FIFO，等待最久的线程先拿锁 | 支持插队，来者可抢锁 |
| 延迟与吞吐量 | 顺序公平，但在高竞争下开销较高、吞吐较低 | 吞吐更高、延迟更低，但可能导致线程饥饿 |
| 构造方式 | `new ReentrantLock(true)` | 默认构造器 `new ReentrantLock()` |
| AQS 中的表现 | `tryAcquire()` 会检查队列前驱避免插队 | `initialTryLock()` 先尝试 CAS，再入队 |
