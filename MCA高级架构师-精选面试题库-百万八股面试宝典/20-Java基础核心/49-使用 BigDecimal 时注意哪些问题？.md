使用BigDecimal时应该注意如下三个方面问题:

### 1. **避免用浮点构造**

```java
new BigDecimal(0.1)
```

会生成类似 `0.10000000000000000555…` 的非精确值。这是因为内部用了二进制近似值。应改为：

```java
new BigDecimal("0.1")
或
BigDecimal.valueOf(0.1)
```

后者通过 `Double.toString()` 转为字符串构造，避免精度问题。M

### 2. **比较时用** `compareTo()`**，不少用** `equals()`

`equals()` 判断不仅比较数值，还比较 scale（小数位数），如 `new BigDecimal("2.0")` 与 `"2.00"` 比较会为 false。而 `compareTo()` 返回 0 表示数值相等。正确用法：

```java
if (a.compareTo(b) == 0) { /* 相等 */ }
```

或者用 `.stripTrailingZeros().equals()` 来规整删除多余零。S

### 3. **除法运算要指定舍入模式**

直接使用 `divide()`，若结果为无限小数会抛 `ArithmeticException`：

```java
new BigDecimal("1.00").divide(new BigDecimal("3.00")); // 异常
```

应指定保留精度和舍入方式，例如：B

```java
divide(divisor, scale, RoundingMode.HALF_UP)
```

确保业务预期明确且稳定。
