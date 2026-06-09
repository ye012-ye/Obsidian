MyBatis 通常不手动编写分页逻辑，而是通过分页插件（如 PageHelper）拦截 SQL 并动态添加分页语句，整个流程如下：M

#### 1. 添加分页插件

在 `mybatis-config.xml` 中配置 PageHelper 插件：

```xml
<plugins>
  <plugin interceptor="com.github.pagehelper.PageInterceptor">
    <property name="helperDialect" value="mysql"/>
    <property name="offsetAsPageNum" value="true"/>
    <property name="rowBoundsWithCount" value="true"/>
  </plugin>
</plugins>
```

这里通过 `helperDialect` 指定数据库方言（MySQL、Oracle 等），`rowBoundsWithCount=true` 表示执行分页时自动生成 `COUNT` 查询获取总条数。

#### 2. 插件拦截与修改 SQL

分页插件作为 MyBatis 的 `Interceptor`，拦截核心查询方法，在执行前：

- 判断是否调用了 `PageHelper.startPage(pageNum, pageSize)`；
- 若触发分页，插件会生成 `COUNT` 查询（若 `rowBoundsWithCount=true`），
- 并将原始 SQL 包装成分页 SQL（例如 MySQL 使用 `LIMIT offset, size`）。

S

#### 3. 执行分页查询

调用方代码示例：

```java
PageHelper.startPage(pageNum, pageSize);
List<User> list = userMapper.selectByCriteria(...);
PageInfo<User> info = new PageInfo<>(list);
```

插件确保第一个执行的 Mapper 方法带上 `LIMIT` 并执行 `COUNT`。`PageInfo` 进一步封装当前页数据、总记录数、页码等信息。

#### 4. 数据库方言处理

插件内置对多种数据库方言支持（如 MySQL, Oracle, SQLServer），负责根据 `helperDialect` 构建正确的分页 SQL 语句片段。

B
