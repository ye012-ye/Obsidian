Spring IoC 容器的启动及 Bean 创建大致包括以下几个步骤，如下清晰地划分为“配置解析”与“Bean 实例化”阶段：M

### 一、配置解析阶段

1. **读取配置元数据**：通过 `BeanDefinitionReader`（XML、注解、JavaConfig）加载配置信息。
2. **解析 Bean 定义**：扫描 `@Component`、`@Configuration`、`@Bean`、`@Import` 注解，生成 `BeanDefinition`。S
3. **触发 BeanFactoryPostProcessors**：在容器刷新前，调用所有注册的 `BeanFactoryPostProcessor`（如 `PropertyPlaceholderConfigurer`）调整 Bean 定义。S

### 二、Bean 实例化与初始化阶段

1. **按照依赖顺序实例化 Bean**：通过构造器或工厂方法创建对象。
2. **属性依赖注入**：执行 setter、字段（或构造器）注入，确保所有依赖准备好。
3. **Aware 回调执行**：如 `BeanNameAware`、`ApplicationContextAware` 等接口方法执行。
4. **BeanPostProcessor（初始化前）调用**：应用自定义逻辑处理代理等。
5. **初始化回调**：执行 `afterPropertiesSet()`（`InitializingBean`）、`@PostConstruct` 或 XML/JavaConfig 指定的 init-method。
6. **BeanPostProcessor（初始化后）调用**：再次应用后置处理器，比如代理创建完成。
7. **Bean 完全初始化**：加载完成，缓存中可通过 `getBean()` 获取使用。

### 三、容器启动完成

所有单例 Bean 实例化、属性注入、初始化流程走完后，ApplicationContext 刷新完成，业务可以正常调用 Bean。B
