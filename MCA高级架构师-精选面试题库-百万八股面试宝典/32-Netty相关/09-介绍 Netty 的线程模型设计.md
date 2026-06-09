Netty 的线程模型基于多 Reactor 架构和事件循环（Event Loop），以提升并发性能和资源利用率。以下从三个方面进行说明：

M

### 一、Boss 与 Worker 的角色分工

在 Netty 中，通过对称设计的 `NioEventLoopGroup` 实现 BossGroup 和 WorkerGroup 部署：

- **BossGroup（主 Reactor）**：通常由一个线程组成，仅负责监听并接收新的连接请求。接收到连接后，将 `SocketChannel` 注册到 WorkerGroup 中以继续处理。
- **WorkerGroup（子 Reactor）**：由多个线程组成（默认线程数≈CPU 核心数×2），负责处理对已有连接的读写 I/O 事件，并驱动 ChannelHandler 中的编解码、业务逻辑执行等具体操作。所有与某个 Channel 相关的事件始终在绑定到它的同一个 Worker 线程中执行，避免竞争与线程切换开销。

### 二、事件循环与线程绑定

- 每个 `EventLoop` 绑定一条线程并维护一个 `Selector`。
- 当 Boss 接收到新连接后，通过 `Register` 操作将 Channel 分配给 Worker 的 EventLoop。此后，该 Channel 的 I/O 和事件处理都由同一线程处理，无需锁机制，效率高。B
- 这种一对一绑定策略确保了线程安全和资源隔离，同时让事件能被快速调度到合适的执行线程。

S

### 三、支持高并发的优化手段

1. **非阻塞 I/O + Reactor 模式**：Boss/Worker 循环使用 Selector 检测事件，避免线程因等待阻塞，从而提升吞吐量。
2. **线程复用与线程池机制**：`NioEventLoopGroup` 使用内部线程池管理 EventLoop，减少线程创建和销毁带来的开销。开发者通过 `new NioEventLoopGroup(nThreads)` 指定线程数以应对不同负载需求。
3. ​**业务线程隔离（可选）：**当业务逻辑耗时较长时，可将这些处理放在自定义的 `EventExecutorGroup` 中执行，避免阻塞 I/O 所属 Worker 线程，维持通道响应性。

B

### 四、示例代码

```java

EventLoopGroup bossGroup = new NioEventLoopGroup(1);
EventLoopGroup workerGroup = new NioEventLoopGroup(); // 默认 CPU*2
ServerBootstrap b = new ServerBootstrap();
b.group(bossGroup, workerGroup)
.channel(NioServerSocketChannel.class)
.childHandler(new ChannelInitializer<SocketChannel>() {
    protected void initChannel(SocketChannel ch) {
        ch.pipeline().addLast(new SimpleChannelInboundHandler<ByteBuf>() {
            protected void channelRead0(ChannelHandlerContext ctx, ByteBuf msg) {
                // I/O 线程中处理业务，慎用耗时操作
            }
        });
    }
});
```

上述结构中，BossGroup 处理新连接，WorkerGroup 负责所有渠道的读写与业务回调，形成高性能、低延迟的异步处理机制。
