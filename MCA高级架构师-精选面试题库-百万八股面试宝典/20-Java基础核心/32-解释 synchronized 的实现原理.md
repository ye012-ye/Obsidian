在 Java 中，`synchronized` 的实现依赖 **对象的监视器（monitor）** 和对象头的 **Mark Word**，并结合 JVM 层面的多种优化策略来保证线程安全和性能。M

​

首先，对象头中的 Mark Word 存储锁的状态、拥有线程 ID、哈希码等信息。当执行 `synchronized` 时，Java 会在字节码中插入 `monitorenter` 和 `monitorexit` 指令，这些指令在 JVM 内部尝试获取或释放对象的监视器锁。最初进入锁时，JVM 检查 Mark Word 状态，并在无竞争的情况下直接获得锁，简化了用户态到内核态的转换过程。

​

接下来 JVM 根据锁竞争情况分别应用三种锁升级机制：S

- **偏向锁（Biased Locking）**：适用于单线程频繁加锁的情况，对象头直接记录线程 ID，无需 CAS 和阻塞操作，极大地减少同步开销。若其他线程竞争，偏向锁会被撤销，升级为轻量级锁。
- **轻量级锁（Lightweight Locking）**：竞争出现后，JVM 在当前线程的栈帧中创建锁记录（LockRecord），使用 CAS 操作更新 Mark Word，并让其他线程进行自旋等待，而不进入阻塞状态。
- **重量级锁（Heavyweight Locking）**：若自旋无效或竞争持续，JVM 将锁膨胀为重量级锁，使用操作系统的互斥机制（如 mutex）阻塞线程，并将监视器附着到对象上，由操作系统调度唤醒。

`synchronized` 支持 **可重入性**，即同一线程可在嵌套的同步块中多次获得同一对象的锁，JVM 在对象头中维护重入计数，仅当所有同步块退出后才真正释放锁。

​

此外，JVM 引入自适应自旋、偏向锁撤销（bulk rebias/revocation）和锁粗化（lock coarsening）、锁消除（lock elimination）等优化技术，进一步提升执行效率。例如，在锁对象在短时间内被频繁加锁和释放时，JVM 可能将多个锁操作合并为一次锁保护块，减少开销。B
