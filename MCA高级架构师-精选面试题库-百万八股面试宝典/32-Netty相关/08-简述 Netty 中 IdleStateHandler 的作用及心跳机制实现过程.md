在 Netty 中，实现心跳机制的核心是 `IdleStateHandler`，它可以监测连接是否处于空闲状态并触发相应事件，从而帮助保持长连接的健康性和及时发现断开。实现过程主要如下三个步骤：

M

### 1. 添加 `IdleStateHandler` 到 Pipeline

在客户端或服务端的 `ChannelInitializer` 中引入 `IdleStateHandler`，并设置三个超时时间参数：

```java
pipeline.addLast(new IdleStateHandler(readerIdleTimeSeconds,
                                      writerIdleTimeSeconds,
                                      allIdleTimeSeconds,
                                      TimeUnit.SECONDS));
```

- `readerIdleTimeSeconds`：读空闲超时，若在该时间内没有接收数据，则触发 `READER_IDLE`。
- `writerIdleTimeSeconds`：写空闲超时，若在该时间内没有写出数据，触发 `WRITER_IDLE`。
- `allIdleTimeSeconds`：所有空闲超时，同时无读写时触发 `ALL_IDLE`。

​

### 2. 在自定义 Handler 中处理空闲事件

通过继承 `ChannelInboundHandlerAdapter` 或 `ChannelDuplexHandler`，在 `userEventTriggered()` 方法中判断事件类型并进行处理。例如：

```java

@Override
public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
    if (evt instanceof IdleStateEvent) {
        IdleStateEvent idle = (IdleStateEvent) evt;
        if (idle.state() == IdleState.READER_IDLE) {
            ctx.writeAndFlush("HEARTBEAT");
        } else if (idle.state() == IdleState.WRITER_IDLE) {
            // 收到写空闲事件，触发心跳
        } else if (idle.state() == IdleState.ALL_IDLE) {
            ctx.close(); // 或重连
        }
    } else {
        ctx.fireUserEventTriggered(evt);
    }
}
```

- 在读空闲时通常发送心跳检测消息；
- 写空闲时可触发主动心跳；
- 全空闲时可以判断连接断开，进行关闭或重连处理。

S

### 3. `IdleStateHandler` 内部触发机制

- `IdleStateHandler` 在 `channelActive()` 中启动定时任务，通过 `schedule()` 调度空闲检测任务。
- 内部每隔设定时间检查：

- `ReaderIdleTimeoutTask` 监测读操作；
- `WriterIdleTimeoutTask` 监测写操作；
- `AllIdleTimeoutTask` 监测读写综合状态。

- 若累计无动作，则触发对应空闲事件，调用 `channelIdle()` 推送到 `userEventTriggered()` 方法。

B
