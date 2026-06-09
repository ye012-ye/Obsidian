### 一、聚合函数

1. **COUNT()、SUM()、AVG()**  
   统计、求和和平均值是数据分析的基础工具。

```plsql
SELECT COUNT(*) AS total_orders,
       SUM(amount) AS total_amount,
       AVG(amount) AS avg_amount
  FROM orders 
 WHERE created_at BETWEEN '2025-01-01' AND '2025-06-30';
```

上面统计半年订单数、总额与平均额，适合生成报告和趋势分析。M

2. **MAX()、MIN()**  
   获取最大或最小值，也可用于查找最近或最早的记录。

```plsql
SELECT MAX(price), MIN(price) FROM products;
```

### 二、数学与数值处理函数

- **ROUND(x, n)**：四舍五入到 n 位
- **ABS(x)**：取绝对值
- **MOD(a, b)**：取模
- 如：

```plsql
SELECT ROUND(3.14159, 2), ABS(-42), MOD(order_id, 10);
```

这些函数在财务统计、分页计算等场景中十分常用。B

### 三、字符串相关函数

- **CONCAT(a, b, …)**：连接字符串

```plsql
SELECT CONCAT(first_name, ' ', last_name) AS full_name FROM customers;
```

- **CONCAT\_WS(sep, …)**：带分隔符拼接

```plsql
SELECT CONCAT_WS('-', country_code, phone) FROM contacts;
```

- **REPLACE(str, from, to)**：字符串替换

```plsql
SELECT REPLACE(url, 'http://', 'https://') FROM links;
```

- **LENGTH(str)**：返回字节长度
- **LOCATE(substr, str)**：查找子串位置，从 1 开始
- **FIND\_IN\_SET(item, list)**：判断是否在逗号分隔列表中

这些函数可用于格式化输出、清洗字符串、校验字段等实际业务场景。S

### 四、日期时间函数

- **NOW()、CURDATE()、CURTIME()** 获取当前日期时间、仅日期、仅时间
- **DATE\_FORMAT(dt, fmt)** 格式化输出，例如：

```plsql
SELECT DATE_FORMAT(order_date, '%Y-%m-%d') FROM orders;
```

- **DATE\_ADD()/DATE\_SUB()**：加减时间
- **DATEDIFF(a, b)**：计算两个日期相差天数
- **DAY(), MONTH(), YEAR()**：提取日期组成部分

这些函数广泛用于报表时间过滤、按天/月/年归档统计、时间戳处理等。M

### 五、逻辑与条件函数

- **IF(expr, trueVal, falseVal)**：条件判断返回值

```plsql
SELECT IF(stock > 0, '有货', '缺货') FROM inventory;
```

- **IFNULL(val, default)**：处理空值，防止结果为 NULL
- **CASE WHEN…THEN…ELSE…END**：更复杂的多分支条件逻辑

适用于在 SQL 中直接实现业务逻辑，减少后端代码处理。B
