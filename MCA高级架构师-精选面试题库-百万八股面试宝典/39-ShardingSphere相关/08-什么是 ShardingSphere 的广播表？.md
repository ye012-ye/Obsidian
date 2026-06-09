ShardingSphere 中的 **广播表**（Broadcast Table）是指在每个分片数据源上都存在，且结构与数据完全一致的一类表。当你需要让多个分片共享相同的小型数据（例如系统字典、配置参数或省份信息），广播表就是一种高效的解决方案。

### 一、核心特性与作用机制

- **全节点一致性**：广播表在所有数据源中统一建表并保持同步，任何插入、更新、删除操作会同时发往每个分片节点执行。
- **避免跨分片 JOIN**：当业务查询需要与庞大分表表关联时，如用于 JOIN 操作的小表被设置为广播表，可以在本地分片直接 JOIN，无需跨数据库访问，性能更高。
- **自动路由与控制简便**：查询广播表时，ShardingSphere 默认只从单一节点读取，并按需执行，不涉及复杂跨表路由。

### 二、配置方法：YAML 与 Java 示例

#### YAML 配置示例

```yaml
rules:
- !BROADCAST
  tables:
    - t_dictionary
    - t_config
```

这段配置会将 `t_dictionary` 和 `t_config` 两个表标记为广播表，自动在所有数据源中保持一致内容与结构。ShardingSphere 在创建数据源时会读取该规则并生效。

​

#### Java API 配置示例

```java
BroadcastRuleConfiguration broadcastRule = new BroadcastRuleConfiguration(Arrays.asList("t_dictionary", "t_config"));
ShardingSphereDataSourceFactory.createDataSource(dataSourceMap, Collections.singletonList(broadcastRule), new Properties());
```

使用 Java API，也可灵活定义广播表规则。

### 三、使用场景与注意事项

- **应用场景**：

- 小体量、几乎不变更的数据（如枚举类型、字典表）；
- 需要频繁与大数据量表关联查询（避免跨分片 JOIN 的性能开销）。

- **使用建议**：

- **数据更新需同步**，避免缓存失效带来的跨节点不一致；
- **适度使用**，应当只针对数据量小、变动少的表；
- **避免误用**：不宜将大表或频繁写的表设为广播表以免写扩散性能下降。
