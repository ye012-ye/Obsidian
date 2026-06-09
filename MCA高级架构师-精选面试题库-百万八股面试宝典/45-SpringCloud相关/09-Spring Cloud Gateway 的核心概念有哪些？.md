Spring Cloud Gateway 是基于 **Spring WebFlux/Netty** 构建的响应式 API 网关框架，其设计核心由三个模块构成：**Route（路由）、Predicate（断言）以及 Filter（过滤器）**，结合 **网关处理流程** 完整支撑请求处理逻辑。

M

### 1. Route（路由）

每条 Route 是一个网关路由规则，包含以下组成部分：

- 唯一标识 `id`
- 路由目标 `uri`（支持 `lb://SERVICE-NAME` 实现基于注册中心的负载均衡）
- 一组 Predicates 判断规则
- 一组 Filters 处理逻辑

当所有 Predicate 条件满足时，Route 被匹配，Gateway 会将请求转发至对应 URI。

### 2. Predicate（断言）

Predicates 为 Java8 的 `Predicate<ServerWebExchange>`，用于判断请求是否应被路由：

- 支持内置断言（如 Path、Method、Header、Cookie 等）
- 支持链式组合逻辑运算（默认为 and 关系）
- 支持用户自定义 Predicate Factory，通过继承 `AbstractRoutePredicateFactory` 可注入复杂逻辑判断

S

### 3. Filter（过滤器）

Filters 分为 **Route-specific GatewayFilterFactory** 与 **GlobalFilter** 两种类型，执行过程包括：

- **Pre-filter（请求前）**：可修改请求头、路径重写、限流、熔断等操作
- **Post-filter（响应后）**：可处理响应结果、日志记录、错误重写等功能  
  `AddRequestHeader`、`RewritePath`、`RequestRateLimiter`、`CircuitBreaker` 等

B

### 核心处理流程

请求处理流程简述如下：

1. 请求进入网关，由 **Gateway Handler Mapping** 判断匹配哪条 Route
2. 若匹配成功，进入 **Gateway Web Handler**
3. **Pre‑filters** 顺序执行，对请求可做修改或校验
4. 请求被 **Proxy 转发** 到后端服务或 `lb://` 地址实现服务发现与负载均衡
5. 收到响应后依次执行 **Post‑filters**
6. 最终响应返回给客户端
