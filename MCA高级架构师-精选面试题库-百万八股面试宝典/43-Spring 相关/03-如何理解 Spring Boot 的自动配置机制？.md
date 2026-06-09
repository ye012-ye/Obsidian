Spring Boot 自动配置通过“约定优于配置”理念，大幅降低手动配置的负担。其核心机制和意义包括：

M

### 1. 核心机制：条件装配 + SPI 加载

- 启用 `@EnableAutoConfiguration`（通常由 `@SpringBootApplication` 内含）后，Spring 启动时会通过 `AutoConfigurationImportSelector` 调用 `SpringFactoriesLoader` 从 `META-INF/spring.factories` 或 `AutoConfiguration.imports` 文件加载自动配置类。
- 每个自动配置类通常被注解 `@Configuration` + 多个 `@Conditional…`（如 `@ConditionalOnClass`、`@ConditionalOnMissingBean`），确保仅在相关环境（如依赖库存在、用户未自定义 Bean 时）创建对应 Bean。

S

### 2. 扫描类路径与依赖驱动

- 启动器（如 `spring-boot-starter-web`）引入 `spring-boot-autoconfigure`，内含大量针对常用技术栈（Web、JPA、消息队列等）的默认配置类 。
- Spring Boot 会检查 classpath，如检测到 Tomcat、HSQLDB、JPA 等时自动实例化相应组件（如 `DispatcherServlet`、`DataSource`）。

B

### 3. 自动配置的可定制性

- 可以通过 `@SpringBootApplication(exclude = ...)` 或 `spring.autoconfigure.exclude` 配置排除不需要的自动配置类。
- 若用户显式定义某 Bean（例如自定义 `DataSource`），相关自动配置会根据 `@ConditionalOnMissingBean` 判断失效，实现覆盖。
