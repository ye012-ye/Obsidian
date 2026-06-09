MyBatis 的架构由多个核心模块协同工作，构成了从配置解析到 SQL 执行再到结果映射的完整流程。以下介绍主要角色及职责：M

#### 1. SqlSessionFactoryBuilder 与 SqlSessionFactory

整个流程始于 `SqlSessionFactoryBuilder`，它解析 `mybatis-config.xml`（或通过 Java API 配置），读取数据源、事务、插件、映射文件等信息，构建 `Configuration` 对象，并生成 `SqlSessionFactory`。后者是应用的主工厂，用来创建会话实例。

#### 2. SqlSession

通过 `SqlSessionFactory.openSession()` 获取 `SqlSession`，它封装数据库连接、事务控制和缓存机制，并提供执行 SQL 的基本方法（如 `selectOne`, `selectList`, `insert`, `update`, `delete`）。在 Spring 整合中，`SqlSessionTemplate` 可替代其角色，提升线程安全与事务管理支持。

#### 3. Mapper 接口与 MappedStatement

Mapper 接口定义业务方法，MyBatis 通过动态代理（`MapperProxy`）与 XML 映射或注解绑定，将接口调用映射到 `MappedStatement` 上。后者包含 SQL 语句、输入输出类型、命名空间等元信息，并由 `Configuration` 管理。

#### 4. Executor 与缓存逻辑

`Executor` 是执行引擎核心，根据不同类型（如 `SimpleExecutor`, `ReuseExecutor`, `BatchExecutor`, `CachingExecutor`），协调缓存检查、SQL 执行及结果处理流程，支持一级、二级缓存优化操作。S

#### 5. StatementHandler、ParameterHandler 与 ResultSetHandler

- `StatementHandler` 负责创建并执行 JDBC `Statement`（或 `PreparedStatement`/`CallableStatement`），将 SQL 发送至数据库；
- `ParameterHandler` 将 Java 方法参数映射填充至 `PreparedStatement`;
- `ResultSetHandler` 将 JDBC `ResultSet` 映射为 Java 对象列表。  
  这些组件通过 `Configuration` 的 `newXHandler` 系列方法实例化，并由 `Executor` 在 SQL 流程中调用。

#### 6. TypeHandler 与动态 SQL（SqlSource、BoundSql）

- `TypeHandler` 用于 Java 和 JDBC 类型间的转换；
- 动态 SQL 由 `SqlSource` 解析，生成 `BoundSql`，其中包含实际 SQL 与待绑定参数。这支持条件拼接、循环赋值、SQL 片段复用等特性。

#### 7. Configuration

作为中央配置中心，`Configuration` 保存了全部环境信息，包括各类处理器、映射语句、插件链、类型别名等，并负责构建动态 SQL、映射组件、拦截器链等核心对象。可通过 XML 或 Java API 方式配置。B
