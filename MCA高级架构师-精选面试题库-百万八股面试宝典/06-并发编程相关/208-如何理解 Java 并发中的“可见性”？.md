Java 并发中的 **可见性** 是指一个线程对共享变量做了修改后，其他线程能够及时看到这个修改值。由于每个线程可能在自己的 CPU 缓存或寄存器中保存变量的副本，若没有同步机制，线程之间就可能看到过期（stale）的数据，导致行为不一致。M

### 1. 可见性问题的产生机制

当多个线程访问同一个共享变量时，若该变量 **不是** 声明为 `volatile` 或没有使用同步控制（如 `synchronized`、`Lock`），写操作可能仅在某线程的本地缓存中更新，还未刷新到主内存。其他线程读取时仍会从自己的缓存读取旧值，从而无法看到最新写入。

### 2. `volatile` 如何保证可见性

将变量声明为 `volatile` 后：

- 每次写操作会 **立即写入主内存**；
- 每次读操作都会 **直接从主内存读取** 最新值；
- 同时，读/写 `volatile` 变量之间会形成 **happens-before** 关系，确保前后指令顺序不被重排序。这样就能保证不同线程对该变量操作的可见性和顺序一致性。S

### 3. 示例

```java
public class SharedFlag {
    private volatile boolean flag = false;
    public void writer() {
        flag = true; // 写操作直写主内存
    }
    public void reader() {
        if (flag) {
            // 一旦 flag 为 true，这里能立即看到修改结果
        }
    }
}
```

在此例中，如果不开启 `volatile`，线程 B 可能长时间读取到 `flag = false` 即使线程 A 已将其设为 `true`。声明为 `volatile` 后，写入立刻生效于主内存，其他线程马上可见。B

### 4. `volatile` 的局限性

虽然 `volatile` 提供 **可见性保障** 和 **内存屏障语义**，但它不保证对该变量的复合操作（如 `count++`） 是原子性的。如果多个线程对同一 `volatile` 变量进行累加，仍需额外同步机制（如 `synchronized` 或 `AtomicInteger`）以避免竞态问题。
