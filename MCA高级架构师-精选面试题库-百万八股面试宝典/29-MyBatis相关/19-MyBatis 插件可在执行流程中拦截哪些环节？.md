MyBatis 使用 JDK 动态代理及责任链模式。初始化时，Configuration 根据 `<plugins>` 标签读取并构建 `InterceptorChain`。创建 Executor、StatementHandler、ParameterHandler、ResultSetHandler 实例时，会依次调用 `interceptorChain.pluginAll()`，生成代理链。执行时，代理会根据 `@Signature` 注入拦截逻辑，并通过 `Invocation.proceed()` 逐层调用下一个拦截器或目标方法。

MyBatis 插件机制（Interceptor）支持拦截 SQL 执行流程中四个核心组件并插入自定义逻辑。这些拦截点具体包括：

#### 1. Executor（执行器）

Executor 管理整个 SQL 执行流程，包括缓存、事务和调用 StatementHandler。插件可拦截其方法如 `query`, `update`, `commit`, `rollback` 等，用于控制 SQL 执行前后行为，例如记录日志、实现缓存或修改执行逻辑。M

B

#### 2. StatementHandler（语句处理器）

它负责将 SQL 语句发送给 JDBC，包括 `prepare`, `parameterize`, `query`, `update`, `batch` 方法拦截。插件可在此处修改或替换生成的 SQL，实现如分页、权限注入等功能。

S

#### 3. ParameterHandler（参数处理器）

在这一阶段，插件可拦截 `getParameterObject` 或 `setParameters` 方法，对传入的参数进行自动填充、加密或校验处理，为 SQL 增加额外参数处理逻辑。

M

#### 4. ResultSetHandler（结果集处理器）

该拦截点位于 SQL 返回结果进行映射时，可拦截 `handleResultSets`, `handleOutputParameters` 等方法，实现结果加工、过滤、结构转换等需求。
