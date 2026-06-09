### 整体流程

RocketMQ 的事务消息采用两阶段提交协议（2PC）结合回查补偿机制来确保发送消息与本地事务最终一致性。核心流程包括：M

1. 生产者向 Broker 发送“半事务消息”（Prepared 状态消息），该消息在消费者不可见。
2. Broker 持久化该消息并确认；
3. 生产者执行本地事务（例如订单落库）；
4. 根据本地事务结果，生产者向 Broker 提交 Commit 或 Rollback 指令；
5. Broker 若收到 Commit 则将消息标记为可消费；若收到 Rollback，则丢弃该半消息；
6. 若 Producer 响应丢失或未知状态，Broker 会周期性触发回查，请求 Producer 返回最终事务状态；
7. Producer 在回查接口中查询本地事务，并回复 Commit 或 Rollback，完成补偿流程。

### 实现细节

**半消息存储与隔离**  
事务消息并不会使用业务 Topic，而是写入特设主题如 `RMQ_SYS_TRANS_HALF_TOPIC`。这类消息带 `PROPERTY_TRANSACTION_PREPARED` 属性，被隔离存储，消费者无法获取。只有在提交后才会转移到业务队列。S

**Commit / Rollback 逻辑**  
本地事务完成后，Producer 通过 `sendMessageInTransaction` 机制触发事务监听器执行 `executeLocalTransaction` 方法。在该方法中判断事务是否成功，并返回 COMMIT、ROLLBACK 或 UNKNOWN。基于该结果，Producer 向 Broker 下发第二阶段指令。

**事务状态回查机制**  
若 Broker 未收到明确指令，会对 `half message` 进行定期扫描，并向 Producer 发起 `checkLocalTransaction` 请求。Producer 根据事务状态回复 Commit 或 Rollback。此机制提供了容错补偿与最终一致性。

B

### 示例伪码

```java
TransactionMQProducer producer = new TransactionMQProducer(...);  
producer.setTransactionListener(new MyTransListener());
producer.start();

sendMessageInTransaction(msg, arg);  // 先发半消息
// 执行本地事务：如写订单表或扣库存
// 返回 LocalTransactionState.COMMIT 或 ROLLBACK 或 UNKNOWN

// Broker 超时后调用 checkLocalTransaction(msg)
// 查询本地事务结果，决定最终提交或回滚
```

通过以上流程，RocketMQ 实现分布式事务消息时，不依赖外部事务协调者，而是通过本地事务控制与 Broker 回查机制，确保生产者与消费者端最终一致性。
