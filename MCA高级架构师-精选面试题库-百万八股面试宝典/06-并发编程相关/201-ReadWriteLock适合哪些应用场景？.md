`ReadWriteLock` 是 Java 中的一个高级并发控制工具，它维护一对锁：**读锁**（`readLock()`）允许多个线程并发读取，但只能在没有写锁时使用；**写锁**（`writeLock()`）是独占的，若有读锁或写锁被持有，写锁线程必须等待。

### 适用场景

- **读多写少**：当共享数据在大多数时间用于读取，只有少数情况进行修改时，使用读写锁能显著提高并发性，例如缓存系统、配置中心、游戏状态读取等。此时多个线程可以同时并发读取，写操作则通过独占锁保护数据一致性。
- **重度读取、轻度写入的数据结构**：此类结构大部分时间用于查询，偶发写入，适用于 `ReentrantReadWriteLock` 实现来减少锁竞争，提升吞吐量。
- **需要兼顾一致性与性能的共享资源**：例如后台监控系统、应用状态读取、文档只读访问等，在保证写操作互斥的前提下允许高并发读操作以提升效率。

### 示例代码

```java
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;
import java.util.HashMap;
import java.util.Map;

public class SharedCache {
    private final Map<String,String> cache = new HashMap<>();
    private final ReadWriteLock rwLock = new ReentrantReadWriteLock();

    public String read(String key) {
        rwLock.readLock().lock();
        try {
            return cache.get(key);
        } finally {
            rwLock.readLock().unlock();
        }
    }

    public void write(String key, String value) {
        rwLock.writeLock().lock();
        try {
            cache.put(key, value);
        } finally {
            rwLock.writeLock().unlock();
        }
    }
}
```

多线程场景中，多个 `read()` 方法可并行执行，不会互相阻塞；但若有线程调用 `write()`，则会等待所有读锁释放，并排它地执行写操作。
