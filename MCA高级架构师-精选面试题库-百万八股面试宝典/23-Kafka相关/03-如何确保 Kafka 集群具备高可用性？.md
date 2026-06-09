Kafka 通过多项机制协同工作，确保在故障发生时还能持续提供服务，这些机制如下：

M

### ​1. 多 Broker 分布式部署

Kafka 集群由多个 broker 组成，topic partition 与其副本分布在不同 broker 节点上。当某个 broker 故障时，其他节点仍能提供读写服务，避免单点故障。

### ​2. 数据冗余与副本机制

- 每个 partition 可配置多副本（replication-factor）。
- Leader 将写入更新复制到 ISR（In-Sync Replicas）列表中，当 leader 故障，Kafka 会从 ISR 中快速选举新的 leader，保证数据一致性和可用性。

S

### ​3. Leader 选举机制

- Kafka 使用 ZooKeeper 或 KRaft 协调通过 ISR 管理 leader 选举，选出最新且同步的副本接管成为 leader，保障写服务不中断。
- 使用 epoch 编号防止老 leader 接管，确保 leader 具备完整数据。

### 4. 高可用保障

- 传统 Kafka 使用 ZooKeeper 集群选举控制器节点，保证至少半数存活维持 quorum。
- 在 KRaft 模式下，用 Raft 协议选出多个 controller，支持 rack awareness，防止整个机架失效时控制服务中断。

B

### ​5. 可配置容忍度

- 通过 `min.insync.replicas` 与 producer 的 `acks=all` 配合，可确保写入需被至少多个 ISR 接收，提升数据耐久性，降低 leader 失效导致的数据丢失风险。
- 可选 `unclean.leader.election.enable=true` 在没有 ISR 可用时允许选非同步副本，以提高可用性，但有丢数据风险。

### ​6. 监控与故障容忍策略

- 可以部署监控系统，实时检测 broker、ISR、controller 状态，自动触发 failover。
