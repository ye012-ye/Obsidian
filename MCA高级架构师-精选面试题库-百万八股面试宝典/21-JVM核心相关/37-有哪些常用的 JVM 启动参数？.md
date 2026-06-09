JVM 启动参数可分为三类：标准设定参数（`-X`）、非标准性能调优参数（`-XX`），以及系统属性（`-D`）。这种结构化的命名方式避免了冲突，确保每个参数在合理的语义命名空间中运行。

#### ​**堆内存设置**

常用的堆大小配置包括：M

- `-Xms<size>` 和 `-Xmx<size>`：指定堆内存初始容量和最大容量，通常设置为相同值来避免扩展暂停，例如 `-Xms1g -Xmx2g` 用于预留稳定的堆空间。
- `-XX:NewSize` 与 `-XX:MaxNewSize`：用于设定年轻代大小，让 Minor GC 的频率与速度达到最佳平衡。
- `-XX:SurvivorRatio` 和 `-XX:MaxTenuringThreshold`：调整 Eden 与 Survivor 区的大小比，以及对象晋升老年代所需的年龄阈值，有助于控制对象晋升行为和内存碎片。

#### ​**垃圾回收行为控制**

- `-XX:+UseG1GC`, `-XX:+UseZGC`, `-XX:+UseConcMarkSweepGC`, `-XX:+UseSerialGC`：选择不同 GC 策略以适配低延迟、高吞吐或兼容性要求。
- `-XX:ParallelGCThreads=<n>`：指定并行 GC 线程数，适配多核环境以加速回收。S
- `-XX:MaxGCPauseMillis=<ms>`：为 G1 指定最大暂停时间目标，有助于满足响应时间 SLA。

#### ​**GC 日志与崩溃调试**

- `-XX:+PrintGCDetails`, `-Xloggc:<file>`：启用 GC 日志记录，便于后续分析。
- `-XX:+HeapDumpOnOutOfMemoryError`, `-XX:HeapDumpPath=<path>`：在 OOM 时生成堆转储文件，帮助诊断内存问题。
- `-XX:+PrintCommandLineFlags`：启动时输出实际生效的 `-XX` 参数配置，可用于监测环境设定。

#### ​**线程栈与调试**

- `-Xss<size>`：设定每个线程的栈大小，防止 `StackOverflowError`。
- `-D<property>=<value>`：设定系统属性，供应用在运行时通过 `System.getProperty(...)` 获取，例如指定工作目录或日志级别。B
