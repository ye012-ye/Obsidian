RabbitMQ 支持多种消息模式，不同模式通过 Exchange 类型和队列绑定实现，为各种业务需求提供灵活的消息处理方式。以下是常见场景及其架构方式：

M

### 1. 点对点（Work Queue / Competing Consumers）

在该模式下，生产者将消息发送到一个队列，多个消费者同时从该队列中拉取并处理消息。RabbitMQ 会自动均衡分发任务，适合用于负载分配或任务处理场景。

这种方式通过一个 queue 和多个消费者共同竞争，实现任务分割与扩展性优化。

### 2. 发布/订阅（Pub/Sub / Fanout）

Producer 把消息发送到 Fanout 类型的 Exchange，Exchange 会将消息广播到所有绑定的队列。每个订阅者都接收相同内容，适用于日志、通知或广播场景。

### 3. 有条件路由（Routing / Direct）

使用 Direct Exchange，消息通过 routing key 与队列的 binding key 进行完全匹配后，才会被路由。适合精确投递到特定队列，常见于按类型分发或单一业务消费场景。

S

### 4. 主题路由（Topic Exchange）

Topic Exchange 支持 `*`（匹配一个词）与 `#`（匹配多个词）通配符路由。生产者使用如 `order.us.created` 的 key，消费者可订阅 `order.*.*` 或 `order.us.#` 等多种匹配模式。此模式适合复杂主题分类场景，可灵活绑定多个队列。

### 5. 头部路由（Headers Exchange）

与 routing key 无关，而是依据消息 header 中字段进行匹配，如 `x-match=all/any` 判定所有或任意字段匹配成功后进行路由。适用于依据属性进行过滤、内容丰富的消息分发场景，但因性能较低，使用较少。

### 6. 请求/响应（RPC）

通过结合点对点与回调机制实现 RPC 模式：客户端发送请求至特定队列，服务端消费并处理后将响应发送至带有 `reply-to` 和 `correlation-id` 的回调队列，客户端接收处理结果。这一模式适合于同步式通信需求，但会引入复杂性和延迟。

B

总结对比：

|  |  |  |  |
| --- | --- | --- | --- |
| **模式** | **Exchange 类型** | **消息投递方式** | **典型场景** |
| 点对点 | 默认 / Direct | 一个队列，多消费者竞争 | Task 处理 |
| 发布/订阅 | Fanout | 广播给所有绑定队列 | 日志、通知 |
| 精确路由 | Direct | 路由键完全匹配 | 类型分发 |
| 主题路由 | Topic | 通配符匹配 routing key | 多主题消息订阅 |
| 属性过滤 | Headers | 基于 header 属性匹配 | 按多属性过滤 |
| Request/Response | Direct + reply queue | 同步请求处理机制 | RPC 调用 |
