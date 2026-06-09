在 Netty 中，“零拷贝”涵盖了用户态与系统调用两方面的优化：既减少 Java 层内存复制，也尽可能借助操作系统机制实现内核态不拷贝。

M

### 1. 用户态内存层面的零拷贝 ​

- **直接缓冲区（DirectByteBuf）**  
  Netty 默认使用堆外内存（Direct Memory），避免了应用数据从 JVM 堆复制到本地缓冲区，针对 Socket 写入减少一次内存拷贝。
- **CompositeByteBuf 组合缓冲区**  
  可以逻辑组合多个 ByteBuf（如 header + body），但不实际复制数据，通过组件引用方式组织内容，效率更高，减少内存复制。
- **slice/duplicate 视图缓冲区**  
  利用 `slice()` 或 `duplicate()` 在不复制数据的基础上生成子缓冲区或副本，多个视图共享同一底层内存，避免冗余复制。
- **wrappedBuffer 包装数组或 ByteBuf**  
  使用 `Unpooled.wrappedBuffer(...)` 直接封装已有字节数组或 ByteBuffer，无需拷贝数据即可转为 ByteBuf 使用。

S

### 2. 利用系统调用的零拷贝

- **FileRegion + sendfile（系统层零拷贝）**  
  Netty 提供 `FileRegion`（如 `DefaultFileRegion`），调用底层的 `FileChannel.transferTo()`/`sendfile()`，支持将文件直接从磁盘内核缓冲区传输至网卡，中间用户空间不传输数据，避免多次复制与上下文切换。

B

### 3. 总结

|  |  |  |
| --- | --- | --- |
| **层面** | **技术方案** | **优点** |
| 用户态 | DirectByteBuf、CompositeByteBuf、slice、wrappedBuffer | 避免 JVM 堆与堆外、多个缓冲间的多次数据复制 |
| 系统调用 | FileRegion + sendfile | 避免用户态与内核态间的数据拷贝，减少上下文切换 |

其中，DirectByteBuf 和 CompositeByteBuf 主要减少 Java 层面自身复制，而 FileRegion 则利用操作系统能力，从根本上消除内核与用户空间的拷贝。两种方式结合，最大化提升高并发、大数据量传输场景下的 I/O 性能。
