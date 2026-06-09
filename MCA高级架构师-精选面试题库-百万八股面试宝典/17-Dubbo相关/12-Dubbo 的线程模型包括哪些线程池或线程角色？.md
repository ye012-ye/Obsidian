Dubbo 在线程模型上采用 Reactor + 线程池架构，将网络 I/O 与业务处理分离，确保高效并发和系统稳定性。以下分角色说明：M

### 1. Acceptor/I/O 线程

- **作用**：负责 TCP 连接建立、断开、读写事件的监听和分发，包括请求、响应及心跳。
- **意义**：采用 Reactor 模式，将 I/O 操作集中于少量线程，不阻塞，提高系统吞吐与资源利用率。

### 2. Dispatcher + 业务线程池

Dubbo 支持多种 Dispatcher 策略（由 `dispatcher` 配置控制）：

- **all**：所有消息（请求、连接事件、断开、心跳）都由业务线程池处理；
- **direct**：全部由 I/O 线程处理；S
- **execution**：仅将请求交给业务线程池，其他事件走 I/O；
- **message**：请求/响应由业务线程池处理；
- **connection**：连接事件由专项线程处理，其余走业务池。

**业务线程池（fixed/cached/limit）**承担

- 请求解码、业务处理；
- 响应编码。  
  这可以避免 I/O 线程被耗时业务阻塞。

### 3. Callback / Provider 线程池

用于 **异步调用回调** 或 `RpcContext.startAsync()` 模式，单独处理异步结果，避免与 I/O 和业务线程池争用资源。B
