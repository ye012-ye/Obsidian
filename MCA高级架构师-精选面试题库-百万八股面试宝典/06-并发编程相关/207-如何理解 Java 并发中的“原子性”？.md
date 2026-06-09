Java 并发中的 **原子性** 是指一个操作或一组操作要么完全执行成功，要么完全不执行，而且在执行过程中不会被其他线程中断或干扰。这意味着操作是不可分割的，执行结果对其他线程来说要么是“都完成了”，要么“完全没发生过”。M

例如，`i++` 虽然看似一个操作，但在底层涉及三步：读取变量值、执行加法、写回结果。若线程 A 只完成第一步后被切换，线程 B 完整执行所有步骤并更新了值，然后线程 A 恢复并写回旧值，就导致最终结果不正确，这正是原子性缺失造成的问题。

Java 对基本类型的普通读写操作（如对 `int` 变量的读写）本身是**原子的**，但对于非原子操作（如复合操作）Java 本身并不能保证原子性。S

为了解决这一问题，Java 提供了以下几种方式保证原子性：

- `synchronized` **或** `Lock`：通过互斥锁确保在同一时刻仅有一个线程执行相关代码块，从而保证操作不会被线程切换中断；
- **原子变量类**：如 `java.util.concurrent.atomic.AtomicInteger`，使用底层 CAS（Compare‑And‑Swap）机制，保证 `incrementAndGet()`、`compareAndSet()` 等操作具有原子性且性能较优。

以下是使用 `AtomicInteger` 的示例：

```java
import java.util.concurrent.atomic.AtomicInteger;

AtomicInteger counter = new AtomicInteger(0);
counter.incrementAndGet();  // 原子地执行读取 + 增加 + 写入
```

在多线程并发执行 `incrementAndGet()` 时，即使所有线程同时操作，也不会出现计数错误。B
