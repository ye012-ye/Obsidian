在 MyBatis 中，防止 SQL 注入的关键在于**避免使用** `${}` **拼接未受信任的输入**。针对 LIKE 查询，有以下两种安全且灵活的方法：

M

#### 1. 在 Java 代码中拼接 `%`，配合 `#{}` 占位符

在 Java 层手动构建带 `%` 的模式参数，例如：

```java
String pattern = "%" + sanitize(name) + "%";
List<User> list = mapper.findByNameLike(pattern);
```

对应的 Mapper XML 使用 `#{pattern}` 自动转义：

```xml
<select id="findByNameLike" resultType="User">
  SELECT * FROM users WHERE name LIKE #{pattern}
</select>
```

这种方式能确保所有参数通过预编译机制处理，避免注入风险，同时使用代码控制模糊匹配行为。S

#### 2. 使用 `<bind>` 标签在 XML 中构造模式

借助 MyBatis 的动态 SQL 能力，在映射文件中拼装包含 `%` 的查询字符串，如下：

```xml
<select id="findByNameLike" resultType="User">
  <bind name="pattern" value="'%' + name + '%'" />
  SELECT * FROM users WHERE name LIKE #{pattern}
</select>
```

`<bind>` 将动态创建新变量 `pattern`，而 `#{pattern}` 在编译期正确转义，完全避免了拼接注入问题。B
