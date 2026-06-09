在 Java I/O 中，**流（Stream）** 是一种处理数据传输的抽象概念，它代表数据从源头到目的地的连续字节序列，就像一条水管中流淌的水。流可以连接多种数据通道，比如文件、网络、内存或控制台，它允许我们以统一方式读写数据，无需关心底层细节。M

​

Java 提供了两大类基础流：`InputStream` 和 `OutputStream`，它们都是抽象类，代表面向字节的输入和输出操作。

`InputStream` **– 读取数据**  
`InputStream` 提供 `read()` 方法，从源（如磁盘、网络或内存） sequentially 读取 byte 或 byte 数组。读取操作会阻塞调用方，直到数据可读、抛异常，或返回 `-1` 表示末尾。它不能定位（seek），只能顺序读取。此类输入流的代表包括 `FileInputStream`、`ByteArrayInputStream`、`PipedInputStream` 等。S

`OutputStream` **– 写出数据**  
`OutputStream` 提供 `write()` 方法，用于将单个 byte 或 byte 数组写入目标（如文件、网络连接、缓冲区等）。它还包含 `flush()` 强制缓冲区输出、`close()` 释放资源的机制。代表包括 `FileOutputStream`、`ByteArrayOutputStream`、`PipedOutputStream` 等。

这些 I/O 流常通过装饰器模式增强功能，例如使用 `BufferedInputStream` 或 `BufferedOutputStream` 增加缓冲能力，`DataInputStream`／`DataOutputStream` 提供按数据类型读写的方法，`ObjectOutputStream` 可以序列化对象。

B

### 使用场景

如果程序需 **读取文件、接收网络数据、从内存流中提取信息**，就使用 `InputStream`；反之，则用 `OutputStream` 来 **写文件、发送网络报文、将数据缓存到内存中**。每次操作都应陪同 `close()` 或 `try-with-resources`，以避免资源泄漏。
