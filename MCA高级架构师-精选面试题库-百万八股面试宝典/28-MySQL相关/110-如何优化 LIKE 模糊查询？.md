MySQL 中 `LIKE` 查询性能主要取决于通配符的位置与索引使用情况。合理优化可显著提升查询效率。

### 1. **利用前缀匹配使用索引**

使用 `LIKE 'prefix%'` 时，MySQL 能利用 B+ 树索引快速定位匹配字符串起始部分，因此此类查询性能优秀（如 `username LIKE 'John%'`）。M

---

### 2. **避免在开头使用** `%`

如果使用 `LIKE '%substr%'`，索引失效，必须全表扫描。针对此情况，可以：

- **创建反向字符串列**，再通过 `LIKE 'xiffus%'` 进行索引匹配；
- 或者使用专门的全文索引（FTS），如 InnoDB 的 Fulltext、自定义 trigram 索引等。S

---

### 3. **加上其他条件限制扫描范围**

在 `WHERE` 中加入时间、状态等过滤条件，缩小数据扫描范围，提高索引命中效率。例如：

```sql
SELECT * FROM users 
WHERE created_at >= '2023-01-01' 
  AND username LIKE 'John%';
```

这样能优先使用索引过滤，再做模糊判断。B

---

### 4. **组合索引 & 选择性字段设计**

若语句包含多个查询条件，可建立 composite index，确保最左匹配原则可中索引。例如 `(status, username)`，并确保首列选择基数高的字段。

---

### 5. **使用 SQL 提示与 EXPLAIN 优化执行计划**

使用 `EXPLAIN` 分析 `LIKE` 查询是否走索引；必要时使用 `USE INDEX`、`IGNORE INDEX` 强制或排除索引，加快查询。

---

### 6. **结合缓存与外部搜索引擎**

对于高频查询，使用应用层缓存（如 Redis）。若文本搜索复杂，用 Elasticsearch、Sphinx 等专用全文搜索引擎替代 `LIKE` 查询。
