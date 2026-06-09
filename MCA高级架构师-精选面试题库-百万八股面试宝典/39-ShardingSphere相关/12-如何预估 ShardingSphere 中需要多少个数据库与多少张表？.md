在进行分库分表设计时，合理估算分片数量十分关键。一般应从 **数据增长预测、单库容量极限、业务访问模式与查询粒度** 等多个维度综合考虑。以下通过一个示例说明完整设计流程。

M

### 一、框架思路与核心考量

1. **预测总数据量**：基于当前数据规模与未来增长趋势，估算数年内的总记录数与容量。
2. **单库容量限制**：结合硬件与运维经验定义每个库的最大容量上限（例如 1TB 或 500GB）。([turn0search3])
3. **分库分表策略选型**：确定逻辑分片键，通常做用户 ID 分库、时间范围分表等组合策略，确保同一用户数据集中，利于事务与查询。
4. **扩展规划**：优选用接近 2 的幂（如 8、16、32）作为库与表的数量，以便未来扩容简单平滑。

S

### 二、示例场景：电商订单系统

假设当前订单表统计如下：

- 当前订单累计：1 亿
- 日均新增订单：100 万
- 预计未来 5 年增长：约 1 亿 + 100 万 × 365 × 5 ≈ **28.25 亿条**
- 每条记录约 1KB；总容量约 **2.8 TB**

若单库承载上限为 **500GB**，则每库最多存储约 5 亿条。

**预估分库数量**：  
2.8TB / 0.5TB ≈ 5.65 → 向上取整为 **8 个数据库**（2 的幂）

**每库分表规划**：  
28.25 亿 / 8 = 3.53 亿条／库；单表控制 5000 万条 → 每库约需要 **8 张表**

**总体分片数**：8 库 × 每库 8 表 = **64 个分片**

B

### 三、分片策略样例实现逻辑

```java
public class OrderShardingStrategy {
    private static final int DB_COUNT = 8;
    private static final int TABLES_PER_DB = 8;

    public static int dbIndex(long userId) {
        return (int) (userId % DB_COUNT);
    }

    public static int tableIndex(Date orderTime) {
        // 基于时间季度分片示例
        int quarter = (orderTime.getMonth() / 3);
        int yearOffset = orderTime.getYear() - 2023;
        return (yearOffset * 4 + quarter) % TABLES_PER_DB;
    }

    public static String tableName(long userId, Date orderTime) {
        return String.format("ds_%d.order_%d", dbIndex(userId), tableIndex(orderTime));
    }
}
```

- **分库**：以 `userId % 8` 决定库编号，保证用户订单集中；
- **分表**：基于订单时间（季度方式）决定表编号，保证时间均匀分布。
