MyBatis 通过明确分层的组件协作，实现从配置读取到 SQL 执行及结果映射的完整流程。以下按阶段说明其核心运作过程：

M

#### 1. 配置加载与 SqlSessionFactory 构建

MyBatis 启动时，`SqlSessionFactoryBuilder` 读取 `mybatis-config.xml` 和映射器（Mapper）文件，解析数据源、事务、插件和映射信息，然后构造出全局唯一的 `Configuration` 对象。基于此，创建 `SqlSessionFactory` 实例，用于后续获取会话使用。

#### 2. 获取 SqlSession 与 Mapper 代理

应用运行中，调用 `SqlSessionFactory.openSession()` 获取 `SqlSession`，此会话封装 JDBC 连接、事务与缓存逻辑。若使用 MyBatis-Spring，则 `SqlSessionTemplate` 提供线程安全支持。随后通过 `sqlSession.getMapper(Mapper.class)` 获取 Mapper 接口的 JDK 动态代理。调用该代理方法即触发 SQL 执行流程。  
S

#### 3. 方法调用触发 MappedStatement

Mapper 代理解析接口方法，将 `namespace + methodName` 组合定位对应的 `MappedStatement`，该实体封装 SQL 语句、参数类型与映射规则。MyBatis 找到后进入执行链进行下一步处理。

#### 4. Executor 执行流程

MyBatis 使用 `Executor`（具体类型如 `SimpleExecutor`, `ReuseExecutor` 等）作为核心，负责 SQL 执行流程：

- 尝试命中一级缓存；
- 没命中则通过 `StatementHandler` 准备 `PreparedStatement`；
- 利用 `ParameterHandler` 完成参数填充；
- 执行 SQL，与数据库交互；
- 由 `ResultSetHandler` 将结果集映射为 Java 对象；
- 最终将结果返回，并根据需要缓存结果（一级或二级缓存）。  
  底层使用 `TypeHandler` 辅助类型映射。

B

#### 5. 清理与资源释放

调用查询或更新方法结束后，如果在 `SqlSession` 的生命周期结束、显式调用 `close()` 或事务提交/回滚时，MyBatis 会释放 JDBC 连接、清理本地缓存，并在必要时刷新缓存层级。

### ​整体流程概览

1. 初始化阶段：配置加载 → `Configuration` 构建 → `SqlSessionFactory` 生成。
2. 会话创建：`SqlSession` 获取 → Mapper 代理生成。
3. 方法调用：定位 `MappedStatement` → Executor 执行（缓存 → SQL 执行 → 结果映射）。
4. 关闭与清理：会话关闭、缓存刷新、事务提交或回滚。
