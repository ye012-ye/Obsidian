Redis 哨兵机制（Sentinel）是一套官方提供的高可用方案，专门用于监控 Redis 主从结构并在主节点失效时自动完成故障转移，确保服务的持续可用性。

M

### ​核心作用

1. **监控（Monitoring）**  
   Sentinel 定时向 Redis 主从节点发送 `PING` 或 `INFO`，用于检测节点是否健康。若某节点长时间无响应，Sentinel 便认为其“主观失联”（SDOWN），并通过 quorum（多数投票）机制确认后，将其标记为“客观失联”（ODOWN）。
2. **自动故障转移（Automatic Failover）**  
   一旦主节点被判定为 ODOWN，哨兵集群将选举一个 leader（由多数 Sentinel 同意），由该 leader 执行以下操作：挑选最佳从节点（基于复制偏移和优先级等），执行 `SLAVEOF NO ONE` 升级该从节点为主，并重新配置其余从节点复制新主。
3. **服务发现（Service Discovery）**  
   Sentinel 会向客户端提供当前主节点的地址。客户端可通过命令如 `SENTINEL get-master-addr-by-name` 获取最新主节点信息，以便自动重连。
4. **分布式协作与容错设计**  
   Sentinel 本身以集群形式运行，建议至少部署三个节点，使用多数派机制（quorum）避免误判，并确保系统拥有高容错能力，即使部分 Sentinel 故障也能正常工作。

S

### 主要流程

- **监控阶段**：Sentinel 周期性心跳检查节点状态，被标记为 SDOWN 时通过 gossip 和其他节点协商确认。
- **判定阶段**：达到 quorum 后标记为 ODOWN。
- **选举 leader**：Sentinel 集群选举一个 leader 节点担当故障切换工作。
- **故障转移**：leader 选出最优从节点完成主从切换，并通知其余从节点指向新主。
- **客户端通知**：新主就绪后，客户端通过 Sentinel 提供的接口获取地址完成连接重定向。

B

**总结**：Redis Sentinel 是一种轻量级但完整的高可用解决方案，以分布式监控、共识判断、leader 选举、主从切换和客户端发现为核心流程，保障 Redis 在主节点失效时能够快速恢复。
