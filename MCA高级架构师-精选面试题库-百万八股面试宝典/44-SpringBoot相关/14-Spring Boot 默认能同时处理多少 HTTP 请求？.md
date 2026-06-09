Spring Boot 默认使用嵌入式 Tomcat，其并发处理能力主要由以下系统参数决定：M

## 一、并发处理能力 = 最大线程数

- 默认 `server.tomcat.threads.max`（或 `server.tomcat.max-threads`）值为 **200**，也就是最多同时可以处理 **200** 个请求线程。

这意味着在高并发场景下，只有 200 个请求会被立即处理，其他请求则被暂时排队等待。

## 二、总连接能力 = max‑connections + accept‑count

- `server.tomcat.max-connections` 默认 **8192**（NIO 模式）；
- `server.tomcat.accept-count` 默认 **100**。

组合起来，Tomcat 最多能保留约 **8292** 个连接，超过该上限的新连接会被拒绝或导致客户端超时。

S

## 三、示例场景

1. **处理能力**：最多 200 个线程同时处理请求，超出后请求进入等待队列或阻塞。
2. **连接承载**：允许多达 8292 个连接持有上下文，超出后将触发拒绝连接或超时。
3. **资源占用**：线程是有限资源，200 个线程实际性能和资源限制有关，不能仅凭线程数推断吞吐能力。

## 四、调优建议

- 根据业务特点、内存与 CPU 资源适度调整 `max-threads`、`max-connections` 及 `accept-count`。
- 如果应用 IO 密集型但少计算，可采用 NIO 或替换 WebFlux 提升并发效率。
- 对于超高并发场景，考虑使用虚拟线程（Java Loom）、更高效的非阻塞架构，或将 Tomcat 更换为 Netty/Undertow。

B
