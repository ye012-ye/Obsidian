在 Java（包括 `SimpleDateFormat` 和 `DateTimeFormatter`）中：

- `"yyyy"` 表示普通的**日历年**（calendar year），即年月日按照常规逻辑显示。
- `"YYYY"` 表示**基于 ISO-8601 周的年份**（week-based year），用于计算周数时可能与日历年不同。

M

### ​常见踩雷场景

跨年时，特别是在**12月最后几天**或**1月第一周**，`"YYYY"` 会导致年份显示异常。例如：S

```sql
LocalDate date = LocalDate.of(2021, 12, 29);
DateTimeFormatter fmtYYYY = DateTimeFormatter.ofPattern("YYYY-MM-dd");
DateTimeFormatter fmtyyyy = DateTimeFormatter.ofPattern("yyyy-MM-dd");

System.out.println(date.format(fmtyyyy));  // 输出 "2021-12-29"
System.out.println(date.format(fmtYYYY));  // 输出 "2022-12-29" （错误！）
```

原因在于这一天所属的 ISO 周被认为是下一年的第一周。B
