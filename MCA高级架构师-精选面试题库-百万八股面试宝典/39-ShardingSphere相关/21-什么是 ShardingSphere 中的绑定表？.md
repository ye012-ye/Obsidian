ShardingSphere 中的 **绑定表**（也叫关联表）是指多张拥有 **相同分片规则和分片键** 的逻辑表组。通过这一机制，ShardingSphere 能显著优化跨表 JOIN 查询的性能。M

首先，绑定表要求相关的主表和子表使用相同的分片键及分片策略，例如 `t_order` 和 `t_order_item` 都以 `order_id` 为分片键并采用同样的 hash 或 range 分片算法。S 在多表关联查询时，系统会依据主表的分片条件路由，将主表和子表路由到相同的数据节点上，从而避免生成笛卡尔积 JOIN 查询。B

举例来说，假设我们执行：

```plsql
SELECT i.* 
FROM t_order o 
JOIN t_order_item i 
  ON o.order_id = i.order_id 
WHERE o.order_id IN (10, 11);
```

若未配置绑定表规则，`order_id = 10` 和 `11` 分别会 rout 至不同片（例如片0和片1），ShardingSphere 会生成四条 SQL，导致大量无效跨分片 JOIN。配置绑定表后，系统只发出两条 SQL：

- `t_order_0 JOIN t_order_item_0`
- `t_order_1 JOIN t_order_item_1`

这样查询更高效，避免跨节点通信，减少数据量。

其次，当查询涉及小字典表（如 product、config 表）时，可使用 **广播表**（Broadcast Table）将其数据复制至所有分片节点。在关联操作中，ShardingSphere 会在本地与广播表执行 JOIN，无需跨库查询，进一步提升效率。

总结而言，绑定表解决了分库分表场景下的跨分片 JOIN 问题，要求关联表分片键一致，在执行时依据主表路由定位子表，从而执行本地 JOIN；结合广播表和必要的字段冗余策略，可实现高性能关联查询。
