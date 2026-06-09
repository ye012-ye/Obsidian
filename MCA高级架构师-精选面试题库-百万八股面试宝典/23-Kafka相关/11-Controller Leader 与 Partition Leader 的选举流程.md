Kafka 通过双层选举机制确保集群元数据协调与分区高可用：M

### 1. Controller Leader（控制器节点）选举

- 每个 Broker 启动时都会尝试在 ZooKeeper 或 KRaft（从 Kafka 2.8+开始）中创建一个 `/controller`（ephemeral）节点。
- **第一个成功创建节点的 Broker 成为 Controller Leader**，负责管理集群的所有元数据与 Partition Leader 的选举工作。
- 若 Controller 挂掉（ephemeral 节点消失），剩余的 Broker 会再次尝试创建 `/controller`，进行新一轮 Controller 选举。
- 在 KRaft 模式下，选举由内部 Raft 协议管理，消除了 ZooKeeper 依赖，由多 Controller（quorum）共同维护元数据一致性。

S

### 2. Partition Leader（分区主副本）选举

- Controller Leader 负责为每个 Partition 在其 ISR（In‑Sync Replicas）集合中选举新的 Partition Leader。ISR 包含所有与当前 leader 保持同步的副本。
- **优先选举 ISR 中的“首选副本”（preferred replica）**，以均衡负载；若 ISR 内无可用副本，并且 `unclean.leader.election.enable = true`，则允许从非 ISR 中选举（可用性优先但可能丢失数据）。
- Partition Leader 选举在以下场景触发：

- Leader 清洁退出（如维护停机）：优雅选举首选副本为 leader。
- Leader 异常故障：Controller 感知 broker 下线后，从 ISR 中快速选举新 leader，通知所有相关 Broker 和客户端更新元数据。

B
