MyBatis 的插件机制依赖 Java 动态代理与责任链模式，在核心组件执行前后插入拦截逻辑，具体流程如下：M

#### 1. 支持拦截的组件

MyBatis 允许插件拦截以下四类核心组件的方法：Executor、StatementHandler、ParameterHandler、ResultSetHandler。每类组件上的具体方法（如 `query`, `update`, `prepare`, `parameterize`, `handleResultSets` 等）都可通过插件进行拦截控制。

#### 2. 拦截器链构建

在 `Configuration` 初始化时，MyBatis 读取 `<plugins>` 配置并注册所有 `Interceptor` 实现。之后，在创建以上组件实例（如 `newExecutor`, `newStatementHandler` 等）时，会调用 `interceptorChain.pluginAll(target)`，将所有插件包装为链式代理，构建拦截器链。S

#### 3. 动态代理执行

插件通过 `Plugin.wrap(target, interceptor)` 方法生成 JDK 动态代理对象。内部使用 `InvocationHandler` 来拦截目标方法调用，并判断是否需要执行插件逻辑（通过注解 `@Signature` 匹配类型、方法与参数签名），如果匹配则调用插件的 `intercept(Invocation)`，否则调用原始方法。

#### 4. 方法调用顺序

拦截器链在执行时按插件注册顺序依次调用 `intercept`，最终由 `Invocation.proceed()` 将控制权传递给下一个插件或最终的目标实现。插件可在方法调用前后插入自定义逻辑，且可通过 `setProperties(Properties)` 接收配置参数。

B

#### 5. 示例结构：

```java
@Intercepts({
    @Signature(type = StatementHandler.class, method = "prepare", args = {Connection.class})
})
public class mashibingPlugin implements Interceptor {
    @Override
    public Object intercept(Invocation inv) throws Throwable {
        // 前置逻辑
        Object result = inv.proceed();  // 调用下一环或目标方法
        // 后置逻辑
        return result;
    }
    @Override
    public Object plugin(Object target) {
        return Plugin.wrap(target, this);
    }
    @Override
    public void setProperties(Properties props) {
        // 读取插件配置参数
    }
}
```
