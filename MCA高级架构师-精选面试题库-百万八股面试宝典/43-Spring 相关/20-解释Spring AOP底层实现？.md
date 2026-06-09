Spring AOP 本质是一个 **基于代理的运行时拦截机制**，它通过为目标对象生成代理并构建“通知责任链”，实现横切逻辑的动态织入。

M

#### 1. **代理对象的创建方式**

当 Spring 容器启动时，若某个 Bean 匹配切点规则（例如被 `@Transactional`、`@AspectJ` 切点等标记），Spring 会自动为其创建代理。  
Spring 根据目标类是否实现接口来决定代理方式：

- 实现接口时优先使用 **JDK 动态代理**，通过 `java.lang.reflect.Proxy` 创建代理实例。
- 若无接口或 `proxy-target-class=true` 配置时，则使用 **CGLIB**，动态生成目标类子类，进行方法增强。  
  这一步主要由 `ProxyFactory`、`AopProxyFactory` 和 `DefaultAdvisorAutoProxyCreator` 在容器初始化阶段完成。

S

#### 2. **切点解析和拦截器链构建**

在创建代理的过程中，Spring 会根据 AspectJ 风格的切点表达式（Pointcut），解析出一些符合条件的切点，并为每个匹配的方法组装一条**拦截器链**，其核心元素包括：

- `Advisor` 封装切点与通知（Advice）
- Advice 类型包括 Before、AfterReturning、AfterThrowing、Around 等
- 这些通知会被 `MethodInterceptor` 拦截器包装，链式组织，形成责任链

构建好的拦截链随着代理对象一起存在，对应每个目标方法调用。

B

#### 3. **运行时调用时的执行流程**

执行流程如下：

1. 调用代理对象的方法，进入代理逻辑；
2. 代理会触发一系列拦截器链：按照责任链模式依次执行，如先执行所有 Before Advice；
3. 遇到 Around Advice，通过 `proceed()` 控制是否继续执行下一个拦截器或目标方法；
4. 如果目标方法执行成功，AfterReturning 通知触发；若异常，执行 AfterThrowing 通知；不管怎样，Finally 通知可确保执行；
5. 最后，拦截链结束，把控制权交回调用者，返回结果或抛出异常。

​

整个流程保证了增强逻辑的可控、可插拔，并且一气呵成与目标方法解耦。
