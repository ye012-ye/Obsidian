ZAB 是 ZooKeeper 使用的一种崩溃恢复原子广播协议，用于确保分布式系统中所有节点以相同顺序接收并应用事务。其设计目标是在领导者故障后依然保持一致性与高可用性，核心包含两个主要阶段：**崩溃恢复阶段（leader election + 状态同步）和消息广播阶段（proposal + quorum 确认）**。M

在崩溃恢复阶段，ZooKeeper 节点首先通过选举确定新的 Leader。新 Leader 会从大多数节点获取其最新已提交的事务 ID，然后同步缺失事务到各 Follower 节点，确保集群处于一致状态后才能继续广播新事务。这个过程类似于 Paxos 的 prepare 阶段。S

消息广播阶段中，Leader 接收客户端事务请求后分配序号并广播给所有 Follower。只有当超过半数节点（quorum）记录并响应 ACK 后，该事务才被 Leader 提交并下发 commit 信息，最终所有节点按照一致顺序应用事务，实现 total order broadcast。ZAB 在保证一致性的同时避免全局排序混乱，并支持 crash-recovery：故障节点恢复后通过同步阶段重加入系统。

ZAB 的设计兼具高性能和一致性保障。在 ZooKeeper 中实施后，每秒可支持数万条广播事务，成为服务端配置管理、分布式锁与协调任务等场景中关键的一致性基础。相较于 Paxos，ZAB 更注重 leader-led 的 total order 和高吞吐，并在恢复过程中加入同步阶段，以防日志不一致问题。B
