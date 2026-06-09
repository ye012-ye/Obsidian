RocketMQ 理论上支持 **推模式（Push）** 和 **拉模式（Pull）** 消费，但实际层面上，无论是 PushConsumer 还是 SimpleConsumer，都是基于 **客户端主动拉取（long-polling）** 实现的。M

下面详细说明：

### 一、Push 模式（DefaultMQPushConsumer）

虽然称之为“推模式”，开发者在使用中感觉像是消息被 Broker 推送至消费者（监听器直接获得消息）。但实际上，客户端内部持续向 Broker 发起长轮询请求，一旦可用消息到达，客户端就会拉取并触发回调。  
这种方式隐藏了拉取细节，对开发者友好，管理消费进度自动完成，适合大多数业务场景。  
底层机制完全由客户端控制 MessagePull、Rebalance、FetchQueue、消息缓存与消费线程池执行处理。

### 二、Pull 模式（DefaultMQPullConsumer 或 LitePullConsumer）

消费者由开发者自己控制何时主动拉取消息，管理消费速率、批量大小、消费偏移量。适合流处理框架或需要精细控制的场景。  
客户端周期性发起 pull 请求，接收消息后处理并手动提交消费进度，控制灵活但实现复杂。S

### 三、底层统一机制说明

无论使用 PushConsumer 还是 PullConsumer，RocketMQ 的消息获取都由客户端拉动完成。PushConsumer 是对拉操作的封装与调度，而并非真正的服务端“主动推送”。Broker 不主动发送数据，而是响应客户端的拉取请求。B

### 四、对比总结

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **模式** | **用户感受** | **控制粒度** | **使用复杂度** | **适用场景** |
| Push（封装拉取） | 消息自动推送给监听器 | 低 | 简单 | 大多数业务系统，快速集成 |
| Pull（显式主动拉取） | 消费者主动控制何时拉取、数量 | 高 | 较复杂 | 流处理、定制消费节奏、调度平台 |

### 伪码示意

```java
// Push 模式
DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("GroupA");
consumer.subscribe("TopicX", "*");
consumer.registerMessageListener((msgs, ctx) -> {
    msgs.forEach(msg -> System.out.println(new String(msg.getBody())));
    return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
});
consumer.start();
```

```java
// Pull 模式
DefaultLitePullConsumer consumer = new DefaultLitePullConsumer("GroupB");
consumer.start();
List<MessageExt> msgs = consumer.poll();  // 显式拉取
```

总之，RocketMQ 虽然提供了“推模式”的接口，但实质上所有消费者行为都源于客户端拉取机制。PushConsumer 将这种行为封装，对开发者透明；而 PullConsumer 则让开发者完全掌控消费流程。
