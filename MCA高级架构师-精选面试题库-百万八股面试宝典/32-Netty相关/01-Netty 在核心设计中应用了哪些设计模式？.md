Netty 是一个高性能、异步事件驱动的网络框架，广泛运用了多种设计模式以提升灵活性和性能：

### 1. **Reactor 模式**

Netty 的线程模型基于 **Reactor** 模式：BossGroup 和 WorkerGroup 分别负责监听事件和处理 I/O。事件循环（EventLoop）负责 demultiplexing 并 dispatch 各种事件，确保高并发下性能稳定。

M

### 2. **责任链/截取过滤器（Chain of Responsibility / Intercepting Filter）模式**

`ChannelPipeline` 和多个 `ChannelHandler` 构成责任链结构或者拦截过滤器。每个事件依次传递给 pipeline 中的 handler，完成解码、编解码、业务逻辑等处理 。

### 3. **观察者（Observer）模式**

`ChannelFuture` 和 `ChannelFutureListener` 实现异步操作的回调机制。写操作注册监听器，操作完成后通知所有监听者，实现观察者模式。

S

### 4. **工厂（Factory）模式**

通过工厂模式创建不同的 Channel 和 EventLoop 实例，如 `NioServerSocketChannel`、`NioEventLoopGroup` 等。用户只需配置类型即可获取相应对象，而无需直接实例化具体类

​

### 5. **模板方法（Template Method）模式**

`ChannelInitializer` 是典型的模板方法：由框架控制流程，用户通过覆盖 `initChannel(...)` 方法配置 pipeline。该模式简化配置并保证标准流程 。

B

### 6. **单例（Singleton）模式**

例如 `PooledByteBufAllocator.DEFAULT`，采用单例模式确保全局有且仅有一个分配器实例，提高内存分配效率。

### 7. **装饰（Decorator）模式**

`ChannelHandler` 的组合机制也类似装饰者模式。可以在 pipeline 中自由插入多个 handler，增强功能，而无需修改原有 handler 代码结构。
