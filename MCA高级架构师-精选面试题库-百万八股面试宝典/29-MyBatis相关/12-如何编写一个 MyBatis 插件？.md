MyBatis 插件可以通过实现 `Interceptor` 接口，在 SQL 执行流程的核心节点插入自定义逻辑。核心步骤如下：M

#### 1. 实现 `Interceptor` 接口

创建一个类，实现 `org.apache.ibatis.plugin.Interceptor`，重写三个方法：

- `intercept(Invocation invocation)`：核心拦截逻辑，在这里可以在调用目标方法前后插入业务处理；
- `plugin(Object target)`：使用 `Plugin.wrap(target, this)` 方法，将自身代理包裹目标对象；
- `setProperties(Properties properties)`：可读取配置文件中 `<plugin>` 标签下的属性。  
  MyBatis 默认支持拦截 `Executor`、`StatementHandler`、`ParameterHandler` 和 `ResultSetHandler` 等组件的方法，具体如 `query`, `update`, `prepare`, `parameterize`, `handleResultSets` 等。

#### 2. 指定拦截目标

使用 `@Intercepts` 和 `@Signature` 注解指定拦截的组件类型、方法名和参数类型，如下示例：S

```java
@Intercepts({
    @Signature(
        type = StatementHandler.class,
        method = "prepare",
        args = { Connection.class, Integer.class }
    )
})
public class mashibingPlugin implements Interceptor {
    @Override
    public Object intercept(Invocation inv) throws Throwable {
        // 前置逻辑
        Object result = inv.proceed();  // 执行目标逻辑
        // 后置逻辑
        return result;
    }
    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }
    @Override
    public void setProperties(Properties props) {
        // 读取 <plugin> 标签配置属性
    }
}
```

`@Signature` 确保只对 `StatementHandler.prepare(Connection, Integer)` 方法创建动态代理。

#### 3. 注册插件

在 `mybatis-config.xml` 中添加如下配置，MyBatis 启动时会自动将插件加入拦截器链：B

```xml
<plugins>
  <plugin interceptor="com.example.mashibingPlugin">
    <property name="someProp" value="someValue"/>
  </plugin>
</plugins>
```

MyBatis 初始化时读取 `<plugins>` 标签，在创建核心组件实例时依次通过 `Configuration.interceptorChain.pluginAll(target)` 包装插件链。

#### 4. 执行时机制

当目标方法被调用，如执行 SQL 时，代理会判断匹配的 `@Signature`，若命中则按插件注册顺序依次调用其 `intercept()` 方法。插件内部可通过 `invocation.proceed()` 将控制权交给下一个插件或最终方法。逻辑可自定义前后处理代码。
