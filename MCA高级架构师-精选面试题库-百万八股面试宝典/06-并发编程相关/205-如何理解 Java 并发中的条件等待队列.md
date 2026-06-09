Java 中的 **条件等待队列**（condition queue，也称 condition variable）是与锁（`Lock` 或 `synchronized` 所关联）配合使用的一种机制，用于让线程在**特定条件未满足时**进入等待状态，并在条件满足时由其他线程唤醒执行。

**首先**，线程在获取锁后，如果某个状态不满足（比如队列已满或为空），它会调用 `await()`（或 `wait()`）释放锁并被挂起，进入条件等待队列，此时不会占用 CPU 资源，并允许其他线程获得锁去修改相关状态。

**然后**，当其他线程在完成相应操作（如出队或入队）后调用 `signal()` 或 `signalAll()`（或 `notify()`/`notifyAll()`），会随机或广播唤醒一个或多个等待线程。这些被唤醒的线程将尝试重新获得锁并继续检查条件。

### 示例代码（基于 `Lock` 与 `Condition`）：

```java
class BoundedQueue<T> {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notEmpty = lock.newCondition();
    private final Condition notFull  = lock.newCondition();
    private final Queue<T> queue = new LinkedList<>();
    private final int capacity;

    public void put(T item) throws InterruptedException {
        lock.lock();
        try {
            while (queue.size() == capacity) {
                notFull.await();
            }
            queue.add(item);
            notEmpty.signal();
        } finally {
            lock.unlock();
        }
    }

    public T take() throws InterruptedException {
        lock.lock();
        try {
            while (queue.isEmpty()) {
                notEmpty.await();
            }
            T item = queue.remove();
            notFull.signal();
            return item;
        } finally {
            lock.unlock();
        }
    }
}
```

在 `put()` 中，如果队列已满，线程会在 `notFull` 条件队列上等待，直到 `take()` 方法唤醒它；同样 `take()` 会在 `notEmpty` 上等待，直到 `put()` 调用 `signal()`。这种方式避免了忙等待，提升性能。

### 注意点

- **条件等待队列本质是线程队列**：挂起线程排队等待特定条件。
- **使用** `while` **循环而非** `if` **判断条件**：是为了防止**虚假唤醒（spurious wakeup）**或通知竞态带来的条件不满足问题。
- **唤醒方式注意**：`signal()` 唤醒一个线程，`signalAll()` 唤醒所有等待线程。通常推荐使用 `signalAll()` 以避免遗漏某些等待者。

### 总结

- Java 并发中的条件等待队列用于在条件未满足时将线程挂起，并在条件满足时唤醒继续执行。
- 使用 `Condition.await()` 或 `Object.wait()` 进行等待，使用 `signal()/notify()` 或 `signalAll()/notifyAll()` 进行唤醒。
- 该机制避免了忙等（busy-wait），提高线程协调效率，是实现生产者消费者模型、限界队列等并发模式的核心工具。
