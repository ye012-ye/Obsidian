堆外内存（Off‑Heap）指的是不由 JVM 堆管理的内存，由 Java 调用操作系统或 native 库手动分配，如 `ByteBuffer.allocateDirect()`、`Unsafe` 或本地分配。下面是对比说明：

1. **优势**

- 不受 GC 管控，可缓解垃圾回收引发的停顿，提高延迟稳定性。M
- 适合大数据缓存、直接 I/O 操作或跨进程共享内存的场景，性能更优。

2. **挑战**

- 需手动释放，若管理不当，易发生内存泄漏。
- 分配释放开销大于堆内存，且需要 JNI，可能影响性能。S
- 默认不可观察，需通过 `-XX:MaxDirectMemorySize` 限制，并依赖监控工具查看使用情况。

3. **使用示例**

```java
ByteBuffer buf = ByteBuffer.allocateDirect(1024);
buf.putInt(123);
buf.flip();
int x = buf.getInt();
buf = null;
System.gc(); // 通知释放 direct buffer
```

也可使用 JDK `MemorySegment` 或第三方库（如 Netty、Chronicle）托管生命周期。B

4. **对比**

|  |  |  |
| --- | --- | --- |
| 特性 | 堆内存（Heap） | 堆外内存（Off‑Heap） |
| GC 管理 | 自动 | 手动 |
| 分配速度 | 较快 | 相对较慢 |
| I/O 效率 | 中等 | 更优，适用于大块数据 |
| 泄漏风险 | 低 | 高 |
