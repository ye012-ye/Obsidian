在 ShardingSphere 中配置数据分片策略主要包括以下关键步骤：定义数据源、配置逻辑表、设置分片策略、配置主键生成方式及辅助规则。整体通过 YAML（或 Java/Spring Boot）方式完成配置，清晰可维护。以下为详细描述。

### 1. 配置数据源（DataSource）

首先在 YAML 文件中定义多个真实数据源，每个对应一个数据库实例。例如：

```yaml
dataSources:
  ds0: !!com.zaxxer.hikari.HikariDataSource
    driverClassName: com.mysql.jdbc.Driver
    jdbcUrl: jdbc:mysql://localhost:3306/ds0
    username: root
    password:
  ds1: !!com.zaxxer.hikari.HikariDataSource
    driverClassName: com.mysql.jdbc.Driver
    jdbcUrl: jdbc:mysql://localhost:3306/ds1
    username: root
    password:
```

这样定义后，ShardingSphere 可自动创建每个数据源对象，无需手写连接池逻辑。

### 2. 定义逻辑表与实际数据节点

在 `rules!SHARDING` 中配置逻辑表（如 `t_order`）以及其实际分片表节点，例如：

```yaml
rules:
- !SHARDING
  tables:
    t_order:
      actualDataNodes: ds$->{0..1}.t_order_$->{0..1}
      databaseStrategy:
        standard:
          shardingColumn: user_id
          shardingAlgorithmName: database_inline
      tableStrategy:
        standard:
          shardingColumn: order_id
          shardingAlgorithmName: table_inline
```

这表示 `t_order` 会分布在 `ds0.t_order_0`, `ds0.t_order_1`, `ds1.t_order_0`, `ds1.t_order_1` 四个表节点上。

### 3. 配置分片算法（Sharding Algorithms）

接着定义用于数据库分片和表分片的算法：

```yaml
shardingAlgorithms:
  database_inline:
    type: INLINE
    props:
      algorithm-expression: ds$->{user_id % 2}
  table_inline:
    type: INLINE
    props:
      algorithm-expression: t_order_$->{order_id % 2}
```

采用 Inline 表达式策略，支持简单取模、Hash、时间范围等算法类型。支持 Precise、Range、Complex、Hint 等算法形式，也可按需扩展自定义算法。

### 4. 设置分布式主键生成策略

为逻辑表配置 keyGenerator 策略，常见有 Snowflake、UUID 等，以确保主键全球唯一，如：

```yaml
keyGenerateStrategy:
  column: order_id
  keyGeneratorName: snowflake
```

ShardingSphere 会基于此生成唯一主键，并可用于分表路由。

### 5. 配置绑定表与广播表（补充策略）

如有多个表间存在关联，如 `t_order` 和 `t_order_item`，可配置绑定表以优化 JOIN 性能：

```yaml
bindingTables:
  - t_order, t_order_item
broadcastTables:
  - t_config
```

绑定表保证同分片键表在同一节点执行 JOIN，广播表则将共享小表复制到所有节点用于本地 JOIN 查询。

### 6. 完整示例配置（YAML ）

```yaml
dataSources:
  ds0: !!...
  ds1: !!...

rules:
- !SHARDING
  tables:
    t_order:
      actualDataNodes: ds$->{0..1}.t_order_$->{0..1}
      databaseStrategy:
        standard:
          shardingColumn: user_id
          shardingAlgorithmName: database_inline
      tableStrategy:
        standard:
          shardingColumn: order_id
          shardingAlgorithmName: table_inline
      keyGenerateStrategy:
        column: order_id
        keyGeneratorName: snowflake
    t_order_item:
      actualDataNodes: ds$->{0..1}.t_order_item_$->{0..1}
      databaseStrategy:
        standard:
          shardingColumn: user_id
          shardingAlgorithmName: database_inline
      tableStrategy:
        standard:
          shardingColumn: order_id
          shardingAlgorithmName: table_inline
  bindingTables:
    - t_order, t_order_item
  broadcastTables:
    - t_config
  shardingAlgorithms:
    database_inline:
      type: INLINE
      props:
        algorithm-expression: ds$->{user_id % 2}
    table_inline:
      type: INLINE
      props:
        algorithm-expression: t_order_$->{order_id % 2}
  keyGenerators:
    snowflake:
      type: SNOWFLAKE
      props:
        worker.id: 123
        max.tolerate.time.difference.milliseconds: 1000
```

ShardingSphere 根据此 YAML 自动生成 `ShardingSphereDataSource`，支持分库分表、主键生成、关联优化、读写分离等功能。
