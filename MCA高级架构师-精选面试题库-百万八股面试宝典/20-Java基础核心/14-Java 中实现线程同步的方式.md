Java 提供了多种线程同步机制，以下为核心方式及适用场景：

### 1. `synchronized`

这是最基础的内置锁机制，可用于方法或代码块，自动获取并释放锁。适用于简洁且不会造成长时间阻塞的轻量同步场景。

**优点**：代码简洁，易于使用。  
**缺点**：不支持尝试锁、超时锁，也无法中断等待。M

### 2. `ReentrantLock`（来自 `java.util.concurrent.locks`）

这是一个可重入的显式锁，提供更高级功能：

- 支持 **公平锁**（保证先等待先获取）。
- 支持 `tryLock()`**、**`tryLock(timeout, timeUnit)`，可控制是否阻塞和等待时长。
- 支持响应性 **中断锁请求（lockInterruptibly）**。

**适用场景**：当需要尝试获取锁、可中断或需要公平调度时更合适，如：S

```java
ReentrantLock lock = new ReentrantLock(true); // 公平锁
try {
    if (lock.tryLock(500, TimeUnit.MILLISECONDS)) {
        try {
            // 执行关键区操作
        } finally {
            lock.unlock();
        }
    } else {
        // 获取锁失败时 fallback 操作
    }
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
}
```

该场景中，如果锁被长时间占用，其他线程不会无限等待，还能中断应对 shutdown 等情况。

B

### 3. `wait`、`notify` / `notifyAll`

这些方法配合 `synchronized` 一起使用，实现线程间的协作与通信，适合生产者-消费者等场景。

### 4. 高级同步工具（来自 `java.util.concurrent`）

- `CountDownLatch`：等待一组线程完成后再继续。
- `CyclicBarrier`：多线程在某个屏障点等待彼此，适合周期性任务。
- `Semaphore`、`Phaser` 等适用于更复杂的并发协调。
