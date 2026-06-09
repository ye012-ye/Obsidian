### 1. 内连接（INNER JOIN）

- 返回两表中 **都匹配** 连接条件的行。M
- 最常用，用于查询关联数据。

```sql
SELECT ... FROM A INNER JOIN B ON A.id = B.a_id;
```

---

### ​2. 左外连接（LEFT JOIN）

- 返回左表的所有行，以及右表中匹配的行；右表不匹配时以 `NULL` 填充。
- 用于以某主表为基准，获取关联或无关联的记录。

```sql
SELECT ... FROM A LEFT JOIN B ON A.id = B.a_id;
```

---

### 3. 右外连接（RIGHT JOIN）

- 与左外连接相反：返回右表的所有行，左表匹配则显示，否则左表列为 `NULL`。
- 可以换用左外连接替代。

```plsql
SELECT ... FROM A RIGHT JOIN B ON A.id = B.a_id;
```

---

### ​4. 交叉连接（CROSS JOIN）

- 返回两表的笛卡儿积，即每行与每行的组合。S
- 少用，适用于需全组合场景。

```plsql
SELECT ... FROM A CROSS JOIN B;
```

---

### 5.自连接（SELF JOIN）

- 将表当作两表处理，通过别名引用自身。
- 常用于层级关系或同表关联查询。

```sql
SELECT a.*, b.* 
FROM employee AS a 
JOIN employee AS b 
ON a.manager_id = b.id;
```

---

### 6.全外连接（FULL JOIN）

- MySQL 不支持 `FULL JOIN`，可用 `LEFT JOIN` 和 `RIGHT JOIN` 联合模拟：B

```sql
SELECT ... FROM A LEFT JOIN B ...  
UNION ALL  
SELECT ... FROM A RIGHT JOIN B ...;
```

- 若需去重用 `UNION`，保留重复则用 `UNION ALL`。
