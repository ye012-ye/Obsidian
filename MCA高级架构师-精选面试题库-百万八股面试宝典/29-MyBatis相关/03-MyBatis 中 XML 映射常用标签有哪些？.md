MyBatis 在 XML Mapper 文件中提供了多种标签，用于定义 SQL 语句、动态 SQL、结果映射和缓存等功能。下面按照分类分别说明：

M

#### 1. **Mapped Statements（4大基本语句）**

这四个是必须的核心标签，用于声明数据库的 CRUD 操作：

- `<select>`、`<insert>`、`<update>`、`<delete>`。  
  它们对应 Java 的 Mapper 方法，通过 `id` 标识语句，通过 `parameterType` 和 `resultType/resultMap` 指定输入和输出的数据映射结构。

#### 2. **结果映射标签：**

- `<resultMap>`：定义复杂结构的映射关系，支持嵌套映射。
- `<association>` 与 `<collection>`：分别用于一对一和一对多的结果嵌套映射。
- `<discriminator>`：根据某一列值动态选择子映射，可用于继承结构。

#### 3. **重用 SQL 片段：**

- `<sql>`：用于定义可复用的 SQL 代码块。S
- `<include>`：在其它语句中引用这些已定义的 SQL 块，避免重复书写。

#### 4. **动态 SQL 控制：**

MyBatis 提供强大的动态 SQL 支持，主要标签包括：

- `<if>`、`<choose>`（配合 `<when>`、`<otherwise>` 使用）、`<trim>` / `<where>` / `<set>`、`<foreach>` 和 `<bind>`。  
  这些标签基于 OGNL 表达式，可用于条件拼接、循环列表处理、变量绑定等。

#### 5. **主键与缓存配置：**

- `<selectKey>`：用于在执行 `insert` 前后获取和设置数据库生成的主键值。
- `<cache>` 与 `<cache-ref>`：配置本 Mapper 的二级缓存策略或引用其它命名空间的缓存。

#### 6. **Mapped Statement 属性配置**

在 `<select>`、`<insert>`、`<update>`、`<delete>` 标签中，还可使用以下属性：

- `flushCache`（查询前是否清空二级缓存）、`useCache`（是否使用二级缓存）、`timeout`、`fetchSize`、`statementType`（普通、预编译、存储过程）等。B
