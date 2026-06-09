Spring Boot 启动包括多个阶段，核心流程如下：

M

### 1. 启动入口与 `SpringApplication` 实例化

- 程序调用 `SpringApplication.run(...)`，创建 `SpringApplication` 对象，用于引导整个应用启动。
- 此时确定应用类型（如 web 或非 web）、注册 `SpringApplicationRunListeners` 等组件。

### 2. 预启动阶段：监听器与环境准备

- 发布 `ApplicationStartingEvent`，可用于日志或监控记录。
- 加载 `Environment`（包括命令行参数、配置文件、环境变量等）并发布 `ApplicationEnvironmentPreparedEvent`。
- 执行注册的 `ApplicationContextInitializer`，为 `ApplicationContext` 进行预处理

S

### 3. 创建 `ApplicationContext` 并注册

- 根据类型实例化合适的 `ApplicationContext`（如 `AnnotationConfigServletWebServerApplicationContext`）。
- 发布 `ApplicationContextInitializedEvent`，完成上下文基本组件注册

### 4. 加载 Bean 定义与处理器注册

- 扫描并加载所有 `@Component`、`@Configuration`、`@Bean` 定义。
- 执行 `BeanFactoryPostProcessor`（如自动配置扫描所用的 ConfigurationClassPostProcessor）。
- 注册所有 `BeanPostProcessor`，为 bean 初始化提供钩子

### 5. 实例化 & 初始化单例 Bean

- 创建所有非延迟加载的单例 bean。
- 生命周期流程包括：实例化 → 注入属性 → 调用初始化前后方法（如 `@PostConstruct`、`afterPropertiesSet()`、init-method）→ `BeanPostProcessor` 启动 AOP 代理等

B

### 6. 事件发布和生命周期完成

- 发布 `ApplicationPreparedEvent` 表示 context 已装载但未刷新。
- 刷新 context，完成 bean 初始化，并触发 `SmartLifecycle` 启动方法。
- 发布 `ApplicationStartedEvent` 通知已启动（但未接收请求）。
- 发布 `AvailabilityChangeEvent`（`LivenessState.CORRECT`），表明活跃。
- 调用 `ApplicationRunner` / `CommandLineRunner` 方法执行自定义启动逻辑
- 最终发布 `ApplicationReadyEvent` 和 `AvailabilityChangeEvent`（`ReadinessState.ACCEPTING_TRAFFIC`），标志应用已就绪可提供服务
