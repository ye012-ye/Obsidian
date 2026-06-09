Sentinel 通过动态规则管理、实时统计与可插拔模式，实现资源级别的精准限流，具体可分为以下几个关键步骤：

M

### 1. 定义受控资源与拦截逻辑

在代码中使用 `@SentinelResource` 注解标记方法或资源名称，通过 `blockHandler` 定制限流触发时的处理方法。当该资源被限流触发时，Sentinel 会抛出 `BlockException`，并调用指定的 `blockHandler` 进行降级处理。

### 2. 配置流量控制规则

使用 `FlowRule` 构造限流规则，包括资源名（resource）、限流阈值（count）、度量类型（QPS 或并发线程数）、关联调用链策略（strategy）以及控制类型（controlBehavior）。通过代码或 Dashboard 加载规则（如 `FlowRuleManager.loadRules(rules)`），使限流生效。

### 3. 实时统计与策略评估

Sentinel 在运行时收集资源的 QPS、并发线程数、响应时间等指标。每次请求进入时，由 `FlowSlot` 遍历对应规则，判断当前是否超出限流阈值，决定是否放行。

Sentinel 支持两种限流维度：

1. **QPS 限流**（请求数/秒）
2. **并发线程数**（最大并发控制）

### 4. 限流算法原理

Sentinel 的限流实现采用近似 **滑动窗口算法**，结合 **计数器窗口技术**，提升统计精度和平滑性。  
**令牌桶（Token Bucket）** 或 **漏桶（Leaky Bucket）** 模式来控制突发流量与平均速率。

- **滑动窗口** 更平滑处理边界请求；
- **Token Bucket** 支持吞吐与短期突发；
- **Leaky Bucket** 保证出流稳定、平滑。

### 5. 集群限流机制

Sentinel 提供集群限流能力，通过引入 **Token Server / Token Client** 模式实现全局流量控制。在该模式下：

- Token Server 统一计算是否允许请求；
- 客户端调用时向 Token Server 获取令牌；
- Token Server 根据规则实时判断限流逻辑；
- 限流规则可设置为平均阈值或全局阈值，并支持失败回退为本地限流。

该方式适合多实例场景下保证全局速率一致性，避免局部节点绕过限流。

S

### 总结限流流程

1. **声明资源与拦截器配置** — 使用 `@SentinelResource` 将方法标记为可控资源，并配置 blockHandler。
2. **加载限流规则** — 通过 `FlowRule` 设置 resource 名称、限流 count、限流方式（QPS/线程数）、控制行为等规则。
3. **运行时流量统计** — Sentinel 监控实时 QPS、线程并发数，由 FlowSlot 评估是否触发限流。
4. **触发 / 拦截逻辑执行** — 在规则触发时，抛出 BlockException 并调用 blockHandler 返回默认或降级响应。

B
