MyBatis 的运行机制可分为两个阶段：**初始化准备阶段**和**执行 SQL 阶段**。

M

#### 初始化准备阶段

首先，MyBatis 从 `mybatis-config.xml` 加载全局配置，包括数据源、事务管理和缓存策略。随后，它会读取一个或多个 Mapper 映射文件，将其中定义的 SQL 语句、参数类型和结果映射信息解析成 Configuration 对象。接着，Configuration 由 `SqlSessionFactoryBuilder` 构建成 `SqlSessionFactory`，这是全局唯一的工厂对象，用于后续生成会话。

S

#### 执行 SQL 阶段

当调用 `SqlSessionFactory.openSession()` 时，会创建一个 `SqlSession` 对象。这个 SqlSession 包含了核心的 `Executor`，处理 SQL 的执行、缓存检查与事务控制。接下来，通过 `getMapper()` 获取 Mapper 接口的代理实例，调用接口方法时由 `MapperProxy` 拦截。

1. `MapperProxy` 根据接口方法找到对应的 `MappedStatement`（绑定了 SQL、参数、结果类型等）。
2. `Executor` 检查一级缓存（session 级）。如存在则直接返回，否则继续执行。
3. 利用 `StatementHandler` 创建并准备 JDBC `PreparedStatement`，再由 `ParameterHandler` 将方法参数绑定到 SQL 占位符上。
4. 执行 SQL 后，`ResultSetHandler` 将 `ResultSet` 转换成 Java 对象（比如 POJO 或 Map）。过程中也可能运用插件机制，以增强功能。
5. 最后，查询结果写入一级缓存，事务由事务管理器控制，结果返回给调用者。

这种机制使 MyBatis 实现了对 JDBC 的高度封装和对 SQL 的完全控制，同时保留缓存与扩展能力。

B

#### 代码示例：

```java
// mashibingMapper.java
public interface mashibingMapper {
    mashibingUser findById(@Param("id") int id);
}
```

```xml
<!-- mashibingMapper.xml -->
<select id="findById" resultType="mashibingUser">
  SELECT * FROM user WHERE id = #{id}
</select>
```

```java
// 使用举例
SqlSession session = sqlSessionFactory.openSession();
mashibingMapper mapper = session.getMapper(mashibingMapper.class);
mashibingUser user = mapper.findById(1);
session.close();
```

在初始化阶段完成配置解析和 SqlSessionFactory 构建；在执行阶段通过 `Executor`、`StatementHandler`、`ResultSetHandler` 等组件完成从方法调用到数据库交互再到对象映射的全过程。
