- channel 是安全的通信机制，用于 goroutine 之间传递数据。
- 创建方式：`make(chan T)`, 或者 `make(chan T, cap)`，cap=0 表示无缓冲，也称同步通道。
- 操作方法：

- `<-ch` 接收，`ch <- x` 发送
- `close(ch)` 用于关闭通道，防止发送方继续发送
- `for v := range ch` 可遍历 channel 直至关闭
