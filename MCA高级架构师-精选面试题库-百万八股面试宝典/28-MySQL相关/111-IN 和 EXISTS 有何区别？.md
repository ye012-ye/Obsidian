在 MySQL 中，`IN` 和 `EXISTS` 都用于子查询筛选，但 **执行策略和性能**上存在关键差异。 M

​

**IN**：

- 将子查询结果整体拉出，构建一个值列表，再逐个比较。
- 使用场景：当子查询返回的行数较少或常量列表时非常高效

​

**EXISTS**：

- 对每一条外层记录，检查子查询是否至少存在一行匹配，一旦找到就停止，不再扫描剩余数据。
- 使用场景：子查询返回大量数据或需要判断“存在性”时，性能优势明显 。

​

示例：S

```plsql
-- 使用 IN：将子查询结果全部加载到列表中
SELECT * 
FROM msb_Employees 
WHERE DeptID IN (SELECT DeptID FROM Departments WHERE location = 'NY');

-- 使用 EXISTS：外层表每行触发子查询，仅需判存在
SELECT * 
FROM msb_Employees e
WHERE EXISTS (
  SELECT 1 
  FROM Departments d 
  WHERE d.DeptID = e.DeptID 
  AND d.location = 'NY'
);

```

- 若 Departments 表很大，用 `EXISTS` 可一旦找到匹配便跳出，效率高于 `IN`。
- 当 Departments 结果只有几个 `DeptID` 时，`IN` 会更快。B
