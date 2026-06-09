下面从五个常见问题出发，深入剖析并提供实际解决方案：

### 1. `COUNT()` 与 `DISTINCT` 统计偏差

当使用 `COUNT(column)` 时，`NULL` 会被忽略，导致统计结果少数据；而 `COUNT(DISTINCT col1, col2)` 遇到任一字段 `NULL`，也会丢掉该行。M  
**解决策略**：

- 全量计数用 `COUNT(*)`。
- 去重时使用 `IFNULL` 或 `COALESCE` 将 `NULL` 替换为默认值，如：

```sql
SELECT COUNT(DISTINCT IFNULL(name,''), IFNULL(mobile,'')) …
```

---

### 2. 非等号条件忽略 `NULL`

`WHERE name != 'Java'` 会跳过所有 `name IS NULL` 的记录，因为 `NULL != 'Java'` 返回未知，不是真。  
**解决策略**：S

- 明确处理 `NULL` 条件：

```sql
SELECT … WHERE name != 'Java' OR name IS NULL;
```

---

### 3. 运算结果被迫为 `NULL`

任何含 `NULL` 的表达式结果为 `NULL`，比如 `salary+1` 或 `CONCAT(name,'-x')`，一旦某个操作数 `NULL`，整个结果都是 `NULL`。  
**解决策略**：  
在运算或拼接时使用 `IFNULL(column, default_value)`补全：

```sql
SELECT id, IFNULL(salary,0)+1 AS salary_plus1 …
```

---

### 4. 聚合函数返回 `NULL`

`SUM(salary)`、`AVG(salary)` 若字段存在 `NULL` 且无其他值，可返回 `NULL`，可能导致业务逻辑空指针等问题。  
**解决策略**：B  
使用 `IFNULL` 或 `COALESCE` 将 `NULL` 转化为可计算值：

```sql
SELECT SUM(IFNULL(salary,0)) AS total_salary …
```

### 5. GROUP BY 与 ORDER BY 无视 NULL

默认情况下排序时 NULL 被视为最小值，聚合和分组也将 NULL值视作相等；可能出现排序结果不符合预期或 NULL 被包含在内。

**解决策略 ：**

排序前先过滤：

```sql
  SELECT … WHERE name IS NOT NULL ORDER BY name DESC;
```

分组时使用 `COALESCE` 替代 `NULL`：

```sql
GROUP BY COALESCE(category,'UNKNOWN')
```

​

---

### 总结：

1. **避免使用** `NULL`：建库阶段尽量定义必要字段为 `NOT NULL` 并设置默认值。
2. **查询时显式处理** `NULL`：常用函数如 `IFNULL`/`COALESCE`，以及 `IS NULL` / `IS NOT NULL` 判断。
3. **一致性约定**：项目中统一规范，用空字符串替代可选文本字段，或统一使用 `NULL`，并通过 `CHECK` 约束强制执行一致性。
4. **慎用** `IN()/NOT IN()`：如果子查询包含 `NULL` 会导致整个条件失效。改用 `LEFT JOIN … IS NULL` 形式可规避此陷阱

。
