ShardingSphere 支持三种分布式事务模式：**LOCAL（本地事务）**、**XA（强一致的两阶段提交）**与 **BASE（柔性事务，如 Seata AT）**。开发者可根据业务一致性需求与性能需求灵活选择。

### 1. 本地事务（LOCAL）

在无需跨库一致性的场景下，ShardingSphere 将 JDBC 的 `commit/rollback` 直接转发到底层各分片数据库，性能开销最低。但这种模式不保证跨库的一致性，适用于事务不会触达多个分片的场景或业务层自行管理一致性。

M

### 2. XA事务（两阶段提交协议）

XA 模式严格遵循 ACID 原则，适用于需要强一致性的短事务场景：

- **准备阶段**：ShardingSphere 发起 `XA START → SQL 执行 → XA END`，收集各分片的提交意向；
- **提交阶段**：所有分片准备成功后统一执行 `XA COMMIT`，若任一分片失败则 `XA ROLLBACK`，确保原子性与一致性。  
  ShardingSphere 支持如 Narayana、Atomikos 等 XA 实现，通过 SPI 集成进入系统。

S

### 3. BASE 式柔性事务（使用 Seata AT）

BASE 模式遵循 **Basically Available、Soft State、Eventual Consistency** 三原则，通过业务级补偿机制实现最终一致性：

- 集成 Seata 的 AT 模式后，ShardingSphere 在事务开始时注册全局事务上下文；
- 执行分片操作后，ShardingSphere 会自动生成补偿 SQL；
- 提交时由 Seata TC 协调，若部分分片失败，自动执行补偿逻辑恢复一致性。  
  该方式性能优越，适合长事务或高并发应用场景。

B
