RocketMQ 提供了多种消费模式，主要包括推送式消费（Push）和拉取式消费（Pull）。在实际应用中，推送式消费模式更为常用。M

以下是推送式消费模式的基本流程：

1. **创建消费者实例**：  
   首先，使用 `DefaultMQPushConsumer` 类创建一个消费者实例，并指定消费者所属的消费组。消费组用于标识一组具有相同角色的消费者实例。
2. **设置 NameServer 地址**：  
   通过 `setNamesrvAddr()` 方法设置 RocketMQ NameServer 的地址。NameServer 是一个轻量级的路由注册中心，负责管理 Broker 的路由信息。
3. **配置消费起始位置**：  
   使用 `setConsumeFromWhere()` 方法指定消费者的消费起始位置。常用的配置有：

- `CONSUME_FROM_FIRST_OFFSET`：从最早的可用消息开始消费。
- `CONSUME_FROM_LAST_OFFSET`：从最新的消息开始消费。
- `CONSUME_FROM_TIMESTAMP`：从指定时间戳的消息开始消费。

4. **订阅主题和标签**：  
   通过 `subscribe()` 方法订阅一个或多个主题，并指定标签过滤表达式。标签用于对消息进行分类，消费者可以根据标签过滤感兴趣的消息。
5. **注册消息监听器**：  
   使用 `registerMessageListener()` 方法注册一个消息监听器。监听器实现了 `MessageListenerConcurrently` 接口，用于处理接收到的消息。
6. **启动消费者实例**：  
   调用 `start()` 方法启动消费者实例，开始消费消息。消费者会在后台线程中持续拉取消息，并通过回调函数处理消息。
7. **处理消息**：  
   在监听器的 `consumeMessage()` 方法中，实现具体的消息处理逻辑。处理完成后，返回 `ConsumeConcurrentlyStatus.CONSUME_SUCCESS` 表示消息消费成功，返回 `ConsumeConcurrentlyStatus.RECONSUME_LATER` 表示稍后重试消费。

S

**代码示例：**

```java
import org.apache.rocketmq.client.consumer.DefaultMQPushConsumer;
import org.apache.rocketmq.client.consumer.listener.ConsumeConcurrentlyContext;
import org.apache.rocketmq.client.consumer.listener.ConsumeConcurrentlyStatus;
import org.apache.rocketmq.client.consumer.listener.MessageListenerConcurrently;
import org.apache.rocketmq.common.message.MessageExt;
import org.apache.rocketmq.common.consumer.ConsumeFromWhere;

import java.util.List;

public class SimplePushConsumer {
    public static void main(String[] args) throws Exception {
        DefaultMQPushConsumer consumer = new DefaultMQPushConsumer("ConsumerGroupName");
        consumer.setNamesrvAddr("localhost:9876");
        consumer.setConsumeFromWhere(ConsumeFromWhere.CONSUME_FROM_FIRST_OFFSET);
        consumer.subscribe("TopicTest", "*");

        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs,
                                                            ConsumeConcurrentlyContext context) {
                for (MessageExt msg : msgs) {
                    System.out.printf("Received message: %s%n", new String(msg.getBody()));
                }
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });

        consumer.start();
        System.out.printf("Consumer started.%n");
    }
}
```

**注意事项：**

- **消息过滤**：消费者可以通过标签（Tag）或 SQL92 表达式进行消息过滤，只消费感兴趣的消息。
- **消费进度管理**：RocketMQ 会自动管理消费进度，确保消息不会重复消费。消费者可以通过 `setConsumeFromWhere()` 方法指定消费起始位置。
- **消费失败处理**：如果消息处理失败，消费者可以返回 `ConsumeConcurrentlyStatus.RECONSUME_LATER`，RocketMQ 会稍后重试消费。
- **负载均衡**：同一个消费组中的多个消费者实例会自动进行负载均衡，分摊消息的消费。

**总结： RocketMQ 的消费者通过推送式消费模式实现消息的消费。消费者实例通过订阅主题和标签，注册消息监听器，启动后即可接收并处理消息。消费者可以灵活配置消费起始位置、消息过滤条件和消费失败处理策略，以满足不同业务场景的需求。**

B
