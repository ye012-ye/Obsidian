在 RabbitMQ 的运行模型中，关键组件包括：M

1. **Broker（消息中间件）**  
   Broker 是 RabbitMQ 的服务器实例，负责管理消息生命周期，包括接收、存储和分发消息。它还控制集群、插件或其他高级特性。
2. **Virtual Host（虚拟主机）**  
   虚拟主机是逻辑隔离单元，用于将资源（队列、交换机、绑定和权限等）分组。你可以在一个 broker 实例上创建多个 vhost，从而隔离不同团队或环境的资源和权限配置。
3. **Connection（TCP 连接）**  
   代表客户端（生产者/消费者）与 broker 之间的物理 TCP 链接。通常保持长连接，用于传输所有后续通道上的数据交互。S
4. **Channel（通道）**  
   这是基于单一 TCP 连接的虚拟逻辑连接，用于发送/接收操作。应用可在同一连接上创建多个 channel，从而支持并行处理和资源复用。
5. **Exchange（交换机）**  
   交换机接收来自生产者的消息，并依据类型（direct、fanout、topic、headers）与绑定关系将消息路由至一个或多个队列中。
6. **Queue（队列）**  
   队列是消息的持久化或内存缓冲区，遵循 FIFO 原则，用于存储等待被消费者消费的消息。
7. **Binding（绑定关系）**  
   Binding 是将 Exchange 和 Queue 关联的方法，定义了消息如何从交换机路由到队列，并可通过 routing key 控制路由规则。
8. **Producer 与 Consumer（进程角色）**

- **Producer（生产者）**：负责创建并发布消息到指定 exchange。
- **Consumer（消费者）**：订阅并从队列中取出消息进行处理，可能使用确认（ack）或拒绝（nack）机制。

这些组件协同工作：生产者通过 connection 创建 channel，将消息发送至 exchange，再通过 binding 路由到队列，最终被消费者消费，构成了可靠且灵活的消息传递系统。B
