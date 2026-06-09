Spring 容器启动时会执行一系列有序流程，核心过程如下：

M

### 1. 创建容器实例 & 准备环境

调用 `new AnnotationConfigApplicationContext(...)` 或 `SpringApplication.run(...)`，创建 `ApplicationContext`，并初始化 **Environment**、资源加载等基础组件。

​

### 2. 注册 BeanDefinition 及扫描

引入所有 `@Configuration`、`@Component`、XML 配置等方式定义的 `BeanDefinition`，并解析注解，如 `@ComponentScan`、`@Import` 等，生成 bean 定义并注册至内部注册表。

S

### 3. 执行 BeanFactoryPostProcessor

在实例化任何 bean 前，Spring 会调用所有 `BeanDefinitionRegistryPostProcessor`（如 `ConfigurationClassPostProcessor`）和 `BeanFactoryPostProcessor`，以实现对 bean 定义或工厂进行定制化处理。

### 4. 注册 BeanPostProcessor

注册所有被定义的 `BeanPostProcessor`，用于后续生命周期回调时拦截 bean 的创建与初始化流程。

B

### 5. 实例化 & 注入非懒加载单例 Bean

容器扫描所有非懒加载的单例 bean，依次进行生命周期流程：

- 合并 bean 定义
- 推断合适构造器
- 实例化对象
- 属性注入
- 初始化前处理（postProcessBeforeInitialization）
- 调用初始化方法（如 `afterPropertiesSet`、`@PostConstruct`、`initMethod`）
- 初始化后处理（postProcessAfterInitialization），此时可生成 AOP 代理。

### 6. 发布 Context 刷新完成事件

所有初始化单例完成后，容器发布 `ContextRefreshedEvent`，允许应用执行启动后动作。

### 7. 完成启动 & 后续处理

启动结束后，容器进入可用状态；根据需要监听其它事件或执行 `SmartInitializingSingleton` 回调等逻辑。
