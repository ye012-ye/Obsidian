Java 中常见的六种 OOM 类型如下，均是基于 JVM 和操作系统的不同内存区域引发：M

#### 1. **Java Heap Space**

- **错误信息**：`java.lang.OutOfMemoryError: Java heap space`
- **原因**：堆中对象数量过多超出最大限制（`-Xmx`）。可能是内存泄漏、一次性加载大量数据等。
- **排查建议**：使用堆快照（Heap Dump）+ MAT 等分析，定位长生命周期对象。
- **防范策略**：优化数据批处理逻辑、关闭泄漏、调整 `-Xmx`。

#### 2. **GC Overhead Limit Exceeded**

- **错误信息**：`java.lang.OutOfMemoryError: GC overhead limit exceeded`
- **原因**：GC 占用过多时间（>98%）但回收率极低（<2%），通常是频繁 GC，但堆仍被填满。
- **排查建议**：开启 GC 日志，分析 GC 行为。
- **防范策略**：调整 GC 策略/堆比例（如 `SurvivorRatio`、新老比例），增加堆内存。

S

#### 3. **Requested Array Size Exceeds VM Limit**

- **错误信息**：`OutOfMemoryError: Requested array size exceeds VM limit`
- **原因**：尝试创建超出 `Integer.MAX_VALUE`（≈2.1 G）大小的数组，即使堆足够，也会失败。
- **排查建议**：查看抛出栈，查找创建大数组的代码。
- **防范策略**：分块处理大文件或数据，避免一次性分配巨型数组。

#### 4. **Direct Buffer Memory**

- **错误信息**：`java.lang.OutOfMemoryError: Direct buffer memory`
- **原因**：通过 NIO 或 ByteBuffer.allocateDirect 分配的直接内存未释放，超出 `-XX:MaxDirectMemorySize` 限制。
- **排查建议**：使用 NMT 报告监控 direct buffer 分配与释放。
- **防范策略**：正确释放 ByteBuffer，或调高 direct 内存限制。

B

#### 5. **Unable to create new native thread**

- **错误信息**：`java.lang.OutOfMemoryError: unable to create new native thread`
- **原因**：操作系统分配线程失败，可能是线程过多、栈空间 (`-Xss`) 太大或本地内存不足。
- **排查建议**：通过线程 dump 查看线程数，定位线程泄漏或超量创建。
- **防范策略**：使用线程池代替无限创建线程、控制栈大小、限制线程数。

#### 6. **Metaspace OOM**

- **错误信息**：`java.lang.OutOfMemoryError: Metaspace`
- **原因**：类信息（元空间）超限，比如动态生成大量类、类加载器泄漏等。
- **排查建议**：使用 NMT 模块监控 Metaspace 使用情况，检查频繁加载的新类/类加载器。
- **防范策略**：避免生成过多动态类，确保 ClassLoader 正确卸载，调整 `-XX:MaxMetaspaceSize`。
