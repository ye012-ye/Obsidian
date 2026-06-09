为了迅速排查慢查询问题，建议按照以下四个步骤分析与优化：

1. **开启并收集慢查询日志或分析器结果**  
   首先，开启 MySQL 的 slow query log 或在 SQL Server 中启用 “Include Actual Execution Plan”。记录执行时间、扫描行数等关键指标，以辨别真正的慢查询。
2. **获取执行计划进行诊断**  
   使用 `EXPLAIN`（MySQL/PostgreSQL）或查看执行计划（SQL Server）深入分析。理解是否存在全表扫描、表扫描代价过高、索引失效、JOIN 顺序不合理等问题。B
3. **校验索引的覆盖与匹配情况**  
   根据执行计划，检查 WHERE、JOIN、ORDER BY 条件涉及的字段是否有索引支持，是否选择了合适的索引。并注意避免过度索引带来的写入开销。S
4. **优化 SQL 语句结构**  
   精简 SELECT，只查询必要字段；避免 SELECT \*；尽可能将子查询替换为 JOIN；减少不必要的 ORDER BY 和 GROUP BY；调整 JOIN 顺序或拆分复杂查询；必要时使用分页和 LIMIT。M
