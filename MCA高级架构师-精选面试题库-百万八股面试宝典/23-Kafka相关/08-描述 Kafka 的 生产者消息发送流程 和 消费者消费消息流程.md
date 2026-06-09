### 一、生产者消息发送流程

1. **客户端构建 ProducerRecord**：序列化 key/value，将消息封装为 `ProducerRecord(topic, partition?, key, value)`。M
2. **分区器选择**：如果指定 partition 则直写；否则根据 key hash 或轮询（StickyPartitioner）决定目标 partition。B
3. **消息积累入批**：`KafkaProducer` 内维护 `RecordAccumulator`，将消息追加到对应 partition 的 batch 中，batch 满或超时触发发送。
4. **Sender 线程发送**：后台 I/O 线程定期发起 send 操作，将 batch 数据打包发给 partition leader。通过 `NetworkClient.poll()` 实现 NIO 网络请求。
5. **Broker 响应确认**：消息到达 leader，写入 page cache 并复制到 followers，依据 `acks` 设置，leader 返回 ack。大流下走批量异步，提升吞吐。
6. **Future + 回调完成**：Producer 收到 ack 后，完成对应 `Future<RecordMetadata>` 或触发回调函数。

### 二、消费者消费消息流程

1. **初始化订阅**：客户端创建 `KafkaConsumer`，通过 `subscribe(topics)` 加入消费组，触发分区分配。
2. **poll 拉取逻辑**：消费者循环调用 `poll(timeout)`，发送 Fetch 请求给 broker leader，包含当前 offset，获取批量消息。
3. **处理与确认**：消费者处理消息，成功处理后调用 `commitSync()` 或 `commitAsync()` 提交偏移，写入 `__consumer_offsets`。
4. **心跳与再平衡**：`poll()` 也负责发送心跳，维持 group membership；没调用导致 session 到期触发再平衡。`max.poll.interval.ms` 控制批处理最大时间。
5. **消费驱动**：消费参数如 `max.poll.records` 控制每次拉取消息量；并发消费由 Spring Consumer Container 控制，通过线程池并行处理多个 consumer 实例。

Consumer：Subscribe → Poll → Fetch → Process → Commit → 心跳/再平衡
