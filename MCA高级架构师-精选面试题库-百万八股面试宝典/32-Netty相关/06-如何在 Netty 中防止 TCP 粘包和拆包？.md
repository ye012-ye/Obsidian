在基于 TCP 的网络通信中，**粘包**（多个逻辑消息合并）与**拆包**（一个逻辑消息被拆成多次接收）是常见问题。Netty 提供多种 `ByteToMessageDecoder` 实现，帮助自动识别消息边界：

M

### ​1. 固定长度解码器（`FixedLengthFrameDecoder`）

用于协议中每条消息长度固定的场景。每次从缓冲区读取固定字节数作为一个完整帧。例如设置为 10 字节，则无论数据如何分段，总是每 10 字节拆分为一条消息。适合格式非常统一的协议。

### ​2. 行分隔解码器（`LineBasedFrameDecoder`）

适合协议以特定换行符，如 `\n` 或 `\r\n` 结尾的情况。该解码器读取直到遇到换行符，将整行内容作为消息处理，避免越界。如果某行超过设置的最大长度，抛出 `TooLongFrameException`。

S

### ​3. 分隔符解码器（`DelimiterBasedFrameDecoder`）

适用于任意自定义分隔符协议，如 `||`、`$$` 等。该解码器使用可变长度分隔符，将其作为消息边界进行拆分。示例中可以构造 `ByteBuf delimiter = Unpooled.copiedBuffer("||".getBytes());`。

### ​4. 基于长度字段的解码器（`LengthFieldBasedFrameDecoder`）

最通用且功能丰富的方式。消息头中包含一个长度字段，且长度字段的位置和字节数可配置。该解码器先读取长度字段确定消息长度，然后完整读取该帧。它支持参数：

- `maxFrameLength`（最大帧长度）；
- `lengthFieldOffset`（长度字段在消息头的位置）；
- `lengthFieldLength`（长度字段所占字节数）；
- `lengthAdjustment`（调整帧长度）；
- `initialBytesToStrip`（剥离头部字节数）

B

### ​示例：使用 `LengthFieldBasedFrameDecoder`

```java
pipeline.addLast(new LengthFieldBasedFrameDecoder(
    1024,       // 最大帧长度
    0,          // 长度字段偏移量
    4,          // 长度字段长度（4 字节 int）
    0,          // 顺序调整
    4           // 跳过长度字段后才输出内容
));
pipeline.addLast(new CustomDecoder()); // 处理拆好的 ByteBuf
pipeline.addLast(new CustomEncoder());
```

这里，Netty 自动在 `ByteToMessageDecoder.decode()` 中累计数据，直到读够一条完整消息，之后交给后续 Handler 处理，无需手动拆分逻辑。
