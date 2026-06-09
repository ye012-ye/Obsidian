**1. Paxos 算法核心流程（Basic Paxos）**  
Paxos 是 Leslie Lamport 提出的经典分布式一致性协议，用于让多数节点就一个值达成共识。角色包括：

- **Proposer（提议者）**：发起建议编号和候选值。
- **Acceptor（接受者）**：对提案进行投票、接受。
- **Learner（学习者）**：得知最终决定结果。

M

核心流程分两步：

**阶段 1：Prepare & Promise**

- Proposer选择一个唯一且递增的编号 n，发送 `Prepare(n)` 给超过半数的 Acceptors。
- 若 Acceptor 接收到的 n 比自身承诺值高，则回复 `Promise(n, acceptedProposal?)`，并承诺不接受更小的编号（软承诺）；同时回传它之前可能接受过的最大编号提案值。

**阶段 2：Accept & Learn**

- Proposer 收到多数 Promise 后，若其中包含已接受过的提案，则选择最大编号对应的值为 V；否则可自由选择。
- 发送 `Accept(n, V)` 给 quorum。
- Acceptor 若未违反承诺，便接受并回复。
- 一旦多数 Acceptor 接受该提案，Proposer 将结果通知所有 Learner，完成共识。

S

**2. 优缺点**

​优点：

- **强一致性**：保证最终只有一个值被选中。
- **容错性**：可容忍网络分区或少数节点故障，保障协议安全

​缺点：

- **实现复杂**：消息交互繁琐，概念不易掌握。
- **性能开销高**：每轮需两次通信往返；多个 Proposer 竞选领导易导致活性问题。

B
