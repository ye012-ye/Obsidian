ShardingSphere 实现读写分离的过程主要基于 **SQL 分析与路由策略**，将写操作定向到主库，读操作负载均衡分发到多个从库，从而提升系统性能与可用性。

### 1. 配置数据源与读写规则

首先，在配置文件（如 YAML 或 Java API）中定义主库（writeDataSource）和一个或多个从库（readDataSourceNames），并指定负载均衡策略（如随机或轮询）。  
例如在 YAML 中：

```yaml
rules:
- !READWRITE_SPLITTING
  dataSources:
    rw_ds:
      writeDataSourceName: master_ds
      readDataSourceNames: [slave_ds_0, slave_ds_1]
  loadBalancers:
    roundRobinBalancer:
      type: ROUND_ROBIN
```

​

### 2. SQL 拦截与解析

应用程序发起 JDBC 请求后，ShardingSphere 的解析层将拦截 SQL，分析逻辑类型（SELECT、INSERT、UPDATE、DELETE），构建 SQL 上下文。基于 SQL 内容判断该操作是读还是写，并提取事务及线程上下文信息。

M

### 3. 决策路由

- 对于写操作（INSERT/UPDATE/DELETE），始终路由至主库。
- 对于读操作（SELECT），ShardingSphere 根据负载均衡策略（如 ROUND\_ROBIN、RANDOM）将查询发送至从库。
- 若同一个线程或连接中前面已执行了写操作，则之后的读操作会被强制发到主库，以确保读–写一致性。

### 4. Hint 强制路由（可选）

用户可通过 `HintManager` 在 JDBC 层显式指定查询必须路由到主库（如一致性要求极高时），支持在同一事务内覆盖默认策略。也可通过 DistSQL Hint 实现无代码控制。

S

### 5. SQL 改写与执行

ShardingSphere 将逻辑 SQL 改写为对应目标数据源的真实 SQL（如修改连接地址、逻辑表名等），并将其并行或串行发送到底层数据库执行。此过程对应用完全透明。

### 6. 返回结果

数据库返回数据后，ShardingSphere 将查询结果封装并返回给客户端。写操作一般不涉及结果归并，读操作如涉及多从库路由，则可能做结果合并（例如顺序或聚合）后返回，但通常读只落在单一从库上，归并成本低。

B

​

**总结**：ShardingSphere 的读写分离功能由以下环节协同完成：

1. 配置主库与多个从库及负载策略；
2. 解析 SQL 判断类型；
3. 路由写操作到主库、读操作根据负载均衡策略分配从库；
4. 支持事务内一致性控制和 Hint 强制路由；
5. 自动改写 SQL 并调度执行；
6. 将结果返回应用，保持透明性。

这种设计使开发者无需关心底层主从节点的具体细节，只需配置规则，ShardingSphere 即可将读写请求自动路由至合适节点，从而实现高可用与高性能的业务访问。
