RabbitMQ 是一个基于 AMQP 协议的高性能消息代理系统，它通过多层组件协作，支持生产者和消费者之间的异步、可靠传输。以下是其核心架构组成及职责：

### 1. Producer（生产者）

生产者是消息的发起者。它构造消息并将其发送到 Exchange 中。每条消息包含主体（payload）和属性（如 routing key、headers、持久性标志等）来指导后续路由。M

### 2. Exchange（交换机）

Exchange 接收来自生产者的消息，根据自身类型（Direct、Fanout、Topic、Headers）与绑定规则（Binding）决定消息应路由至哪一个或多个队列。它是消息分发的核心控制点。S

### 3. Binding（绑定）

Binding 定义了 Exchange 与 Queue 之间的关系，指定参数（如 routing key 模式或 header 匹配）来过滤消息，实现精细路由控制。B

### 4. Queue（队列）

队列是消息的暂存仓库，按照 FIFO 规则存储生产者发送的消息，直到消费者获取并 ACK 确认处理。队列可配置为持久化，以防重启造成数据丢失。M

### 5. Consumer（消费者）

消费者订阅队列，从中拉取或被推送消息。消费端处理完后可以发送 ACK、NACK 或 Reject。通过 QoS（如 prefetch）机制，可控制并发处理能力。B

### 6. Connection / Channel（连接与通道）

- **Connection**: 底层 TCP/TLS 连接，客户端与服务器的网络通信桥梁，建议长连接复用资源。
- **Channel**: TCP 上的逻辑通信渠，轻量高效，支持多并发操作。推荐为每个线程或会话开独立通道。M

### 7. Virtual Host（虚拟主机）

虚拟主机是逻辑隔离单元，可在同一 broker 实例中创建多个 vhost，用于隔离资源（交换机、队列、权限等），适合多租户或多环境部署。

**消息流程简述：**
