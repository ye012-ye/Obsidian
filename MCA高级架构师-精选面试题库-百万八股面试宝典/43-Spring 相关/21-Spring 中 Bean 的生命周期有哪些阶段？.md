Spring 容器管理 Bean 的生命周期主要分为四个阶段：

M

### 1. **实例化阶段（Instantiation）**

Spring 使用反射、静态工厂或实例工厂创建 Bean 对象。此时 Bean 尚未注入属性，也未调用任何回调方法。

### 2. **依赖注入阶段（Dependency Injection）**

Spring 将属性注入 Bean，包括通过构造函数、setter 或 `@Autowired`。此阶段也包括解析 `Aware` 接口，如 `BeanNameAware`、`BeanFactoryAware` 等。BeanPostProcessor 的 `postProcessBeforeInitialization()` 方法会在此阶段注入完成后调用。

S

### 3. **初始化阶段（Init）**

Bean 通过多种方式完成初始化：

- 执行 `@PostConstruct` 注解的方法
- 实现 `InitializingBean.afterPropertiesSet()` 方法
- XML 或 `@Bean(initMethod=...)` 指定的初始化方法
- BeanPostProcessor 的 `postProcessAfterInitialization()`，如生成 AOP 代理  
  同时，这里会处理 AOP、事务代理等细节，完成最终准备。

B

### 4. **销毁阶段（Destroy）**

当 Spring 容器关闭时，单例 Bean 会进行清理：

- 执行 `@PreDestroy` 注解的方法
- 实现 `DisposableBean.destroy()` 方法
- XML 或 `@Bean(destroyMethod=...)` 指定的销毁方法  
  原型 Bean 不自动销毁，需手动管理。
