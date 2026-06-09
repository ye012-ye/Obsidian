MyBatis 的动态 SQL 是一种强大的功能，它允许在运行时依据参数或逻辑条件灵活构建 SQL 语句，从而避免写大量重复代码并提升可维护性。

M

首先，动态 SQL 的基础是 MyBatis 提供的 XML 标签，这些标签会被解析成 `SqlNode`，组成 `SqlSource`，在执行时结合上下文参数动态生成最终的 `BoundSql`。主要标签包括：

- `<if>` 用于判断条件是否满足，决定是否拼接代码片段；
- `<choose>/<when>/<otherwise>` 类似于 Java 的 `switch-case` 结构，仅拼接符合条件的分支语句；
- `<trim>`、`<where>` 和 `<set>` 用于自动处理 SQL 前缀（如去掉多余的 `AND`、添加 `WHERE` 或 `SET` 关键字）；
- `<foreach>` 遍历集合变量，生成如 `IN (...)` 或批量插入语句。

S

例如：

```xml
<select id="searchProducts" resultType="Product">
  SELECT * FROM products
  <where>
    <if test="name != null">
      AND name LIKE CONCAT('%', #{name}, '%')
    </if>
    <if test="minPrice != null">
      AND price &gt;= #{minPrice}
    </if>
    <if test="maxPrice != null">
      AND price &lt;= #{maxPrice}
    </if>
  </where>
</select>
```

在这个例子中，只有当 `name`、`minPrice` 或 `maxPrice` 非空时，才会在最终 SQL 中出现对应条件，避免无效或多余的逻辑。

MyBatis 在加载映射文件时，将标签解析为 `SqlNode`，运行时利用参数上下文逐一判断条件，将正确的 SQL 分段拼接成可执行语句，再由 JDBC 执行并映射结果。

B
