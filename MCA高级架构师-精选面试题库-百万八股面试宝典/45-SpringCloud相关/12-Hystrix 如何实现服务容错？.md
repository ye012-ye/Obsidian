Hystrix 是 Netflix 提供的经典容错框架，尽管已进入维护阶段，但其 **六大核心机制**仍为分布式系统提供强有力的保护：M

### 1. 熔断器（Circuit Breaker）

*作用机制*：Hystrix 通过监控一段时间内的错误率、失败次数和响应延迟，判断调用是否异常。当错误率超过阈值后，熔断器进入 **Open 状态**，立即拒绝后续请求（快速失败或 fallback），避免继续打击故障服务。过一段冷却时间后进入 **Half‑Open 状态**，尝试少量请求探测服务是否恢复，若恢复则恢复为 **Closed 状态**。

### 2. 降级（Fallback）

*作用机制*：当调用异常、超时、线程池拒绝或熔断器打开时，Hystrix 会触发 fallback 逻辑。开发者可提供备用方法，如返回默认数据、缓存值或调用替代服务，以保障系统核心功能的可用性。

```java
@HystrixCommand(fallbackMethod = "fallbackValue")
public String callExternal() { … }
public String fallbackValue() { return "default"; }
```

### 3. 请求缓存（Request Caching）

*作用机制*：若多次调用输入参数相同的方法，Hystrix 可缓存第一次调用的结果，重复请求直接命中缓存，避免重复调用远端服务，提升性能。S

### 4. 请求合并（Request Collapsing）

*作用机制*：Hystrix 能将多个并发调用合并成一个批量请求发送，如对同一资源的多次查询，集中合并后再拆分响应，减少网络开销。

### 5. 隔离机制（Thread Pool 或 Semaphore）

*作用机制*：Hystrix 默认为每个依赖服务分配独立线程池（bulkhead 模式），请求超出容量则立即拒绝并触发 fallback，避免一个依赖服务耗尽主线程池资源。也可以使用信号量模式（Semaphore）进行并发限制但不支持超时。

### 6. 实时监控与度量支持

*作用机制*：Hystrix 提供丰富的运行指标，包括命令执行状态、错误率、执行时间、线程池使用情况等，并可通过 Hystrix Dashboard 和 Turbine 聚合展示多实例监控数据，帮助及时诊断系统健康状况。B

##
