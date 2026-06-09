ShardingSphere 提供了灵活的分片算法体系，可满足多种业务场景下的分片需求。主要算法类型包括：**标准算法（Standard）**、**复杂算法（Complex）**、**Hint 算法（Hint）**，以及 **自动算法（Auto）**，它们各有使用场景和优势。M

### 1. **标准分片算法（Standard Sharding）**

适用于单一分片键的业务场景，通过精准算法处理 `=` 和 `IN` 查询，和可选范围算法处理 `BETWEEN...AND`、`>`、`<` 等范围查询。

- **PreciseShardingAlgorithm**：用于 `=` 和 `IN` 操作，将分片键映射至目标数据节点。
- **RangeShardingAlgorithm**（可选）：用于处理范围查询，否则会触发全表路由。  
  此类算法适用于 hash、range 等单键分布场景。

### 2. **复杂键分片算法（ComplexKeysShardingAlgorithm）**

当业务场景中涉及多个字段联合决定分片时使用此算法。开发者需自行实现逻辑，例如结合 userId 与 orderId 等多个维度进行分片。适合复杂业务逻辑下的多键分片策略。S

### 3. **Hint 分片算法（HintShardingAlgorithm）**

Hint 分片允许开发者在 SQL 层外部通过 `HintManager` 注入分片键值，而不是依赖 SQL 中的查询条件。这种方式适用于业务决定分片值无法体现在 SQL 语句的场景，如跨系统注入、审计等。

### 4. **自动分片算法（Auto Sharding Algorithm）**

ShardingSphere 从 5.x 版本起引入了一类“自动化”的分片算法（Auto）供快速分片场景使用，包括：

- `MOD`（Modulo、余数算法）
- `HASH_MOD`（Hash 模余算法）
- `VOLUME_RANGE`（基于容量的范围算法）
- `BOUNDARY_RANGE`（基于边界的范围算法）
- `AUTO_INTERVAL`（按时间间隔自动分片）

这些算法配置简单，适合日期、连续 ID 或固定容量分片需求。B

## 比较与适用场景总结

|  |  |  |
| --- | --- | --- |
| **算法类型** | **核心场景** | **优势简述** |
| Precise | `=`／`IN` 单值查询 | 精准定位，性能高 |
| Range | 范围查询（如 `BETWEEN`） | 支持范围拆分，防止跨库扫描 |
| Complex | 多字段联合作为分片键 | 灵活应对复杂业务逻辑 |
| Hint | 分片值不在 SQL 中体现 | 外部控制，兼容特殊业务路径 |
| Modulo／Hash | 均匀分布、ID 取模场景 | 简单易配置，适合平滑分布 |
| Boundary／Volume／Interval | 按容量或时间分片 | 自动扩展、可控边界或时间管理 |

- **典型应用**：

- 订单 ID 取模分表：使用 Modulo/Hash 算法；
- 时间范围分片：使用 Auto Interval；
- 复杂业务组合：使用 ComplexKeysShardingAlgorithm；
- SQL 本身不包含分片键：使用 Hint 算法。

### 小结:ShardingSphere 提供了 **Standard**（Precise + Range）、**ComplexKeys**、**Hint** 三种主流策略以及 **Auto** 系列自动算法（Modulo、Hash、Boundary‑Range、Volume‑Range、Interval）供业务选择。开发者可灵活配置这些算法或依据业务需求自行实现 SPI 扩展，以满足各种分片场景需求。
