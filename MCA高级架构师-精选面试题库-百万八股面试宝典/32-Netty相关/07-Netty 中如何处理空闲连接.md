在 Netty 中，处理闲置（idle）连接的核心机制是通过 `IdleStateHandler` 配置定时监测空闲状态，并结合自定义 Handler 在事件触发后执行相应动作，如发送心跳、关闭连接或重连，以保证系统资源合理利用与连接的健康状态。

### 一、将 `IdleStateHandler` 加入 Pipeline

在 `ChannelInitializer` 中，可以根据业务需求设置读、写或总空闲时间。例如：

```java
pipeline.addLast(new IdleStateHandler(60, 30, 0, TimeUnit.SECONDS));
```

- **readerIdleTimeSeconds** = 60：若 60 秒内无读操作，触发 `READER_IDLE`；
- **writerIdleTimeSeconds** = 30：若 30 秒内无写操作，触发 `WRITER_IDLE`；
- **allIdleTimeSeconds** = 0：不监控全空闲。M

### 二、自定义 Handler 捕获并处理空闲事件

通过继承 `ChannelInboundHandlerAdapter` 或 `ChannelDuplexHandler`，重写 `userEventTriggered()` 方法：

```java
@Override
public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
    if (evt instanceof IdleStateEvent) {
        IdleStateEvent e = (IdleStateEvent) evt;
        if (e.state() == IdleState.READER_IDLE) {
            System.out.println("读超时，关闭连接");
            ctx.close();
        } else if (e.state() == IdleState.WRITER_IDLE) {
            System.out.println("写超时，发送心跳");
            ctx.writeAndFlush("PING");
        }
    } else {
        super.userEventTriggered(ctx, evt);
    }
}
```

这样可以根据不同空闲类型采取不同操作，如断连或心跳。S

### 三、底层机制与事件触发流程

1. `IdleStateHandler` 在 `channelActive()` 初始化时，会基于读/写/全部空闲时长，使用 `EventLoop.schedule()` 设置定时任务（如 `ReaderIdleTimeoutTask`）。
2. 定时任务定期检查：若到期期间未发生读/写事件，则触发相应 `IdleStateEvent`；
3. 事件通过 `ctx.fireUserEventTriggered(evt)` 传递给 Pipeline 中下一个 Handler；
4. 最终触发开发者自定义的处理逻辑（如关闭连接或发送心跳），保障系统健康与资源回收。

B
