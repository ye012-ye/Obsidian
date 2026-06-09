Java 中的死锁（deadlock）是多个线程互相等待对方释放锁，导致系统陷入僵局的现象。产生死锁的四个必要条件包括：互斥条件、持有且等待、不允许抢占、以及循环等待。只要破坏其中之一，死锁便可以避免。

### 1. 锁顺序一致（Prevent Circular Wait）

最简洁有效的做法是确保所有线程以**统一、固定的顺序获取多个锁**，即避免循环等待。例如：

```java
void transfer(Account a, Account b, int amount) {
    Object first = a.hashCode() < b.hashCode() ? a : b;
    Object second = a.hashCode() < b.hashCode() ? b : a;
    synchronized(first) {
        synchronized(second) {
            // 转账操作
        }
    }
}
```

确保所有线程按相同顺序请求锁，即使资源不同也不会出现交叉等待的情况，从而避免死锁。

### 2. 限时尝试加锁（Lock Timeout）

使用 `ReentrantLock.tryLock(timeout)` 等机制，在等待锁超时后放弃请求并回退，比如：

```java
if (lock1.tryLock(1, TimeUnit.SECONDS)) {
    try {
        if (lock2.tryLock(1, TimeUnit.SECONDS)) {
            try {
                // 操作
            } finally {
                lock2.unlock();
            }
        }
    } finally {
        lock1.unlock();
    }
}
```

这样可避免线程永远等待某一锁，减少死锁概率。

### 3. 避免嵌套锁（Avoid Nested Locks）

尽量避免在一个线程中同时持有多个锁；如果业务逻辑必须用多个锁，也要确保**锁获取简单、顺序固定**。嵌套锁是最常见的死锁源头，尽量避免复杂的锁调用层次。

### 4. 死锁检测与恢复机制

在一些复杂场景中，无法预知全部锁顺序或资源冲突，此时可使用死锁检测技术：

- 使用 `ThreadMXBean.findDeadlockedThreads()` 检查 JVM 中是否存在死锁线程；
- 如果检测到死锁，可记录日志、报警，甚至采取**回滚、重启线程或释放部分资源**等方式恢复系统运行。

也可以以银行家算法等形式在资源分配系统中预防死锁。

### 示例对比：

**不安全情况（可能死锁）：**

```java
synchronized(a) {
    Thread.sleep(100);
    synchronized(b) {
        // 操作
    }
}

synchronized(b) {
    Thread.sleep(100);
    synchronized(a) {
        // 操作
    }
}
```

**安全做法（统一锁顺序）：**

```java
List<Object> resources = Arrays.asList(a, b);
resources.sort(Comparator.comparingInt(System::identityHashCode));
synchronized(resources.get(0)) {
    synchronized(resources.get(1)) {
        // 操作
    }
}
```

### 总结

- 死锁的核心是“循环等待”，避免的最佳策略是**统一锁获取顺序**；
- 还可通过**加锁超时**、**减少锁持有**或使用高级并发工具减少锁使用；
- 对于复杂系统，可引入**死锁检测机制**定期扫描并恢复；
- 实战中，也可结合业务场景压测与代码审查，确保系统设计免疫常见死锁模式。
