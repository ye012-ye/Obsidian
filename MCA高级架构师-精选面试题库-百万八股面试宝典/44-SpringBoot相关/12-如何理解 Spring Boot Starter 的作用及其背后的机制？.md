Spring Boot 的 Starter 是一套“开箱即用”的依赖描述模板，整合常见功能所需的库、自动配置和默认属性，帮助开发者快速启动项目，并确保依赖和配置的兼容性。背后机制可从以下几个方面理解：

M

### 1. 预定义依赖打包

每个 Starter（如 `spring-boot-starter-web`、`spring-boot-starter-data-jpa`）在 `pom.xml` 中声明了一组互相关联的核心依赖，且由 Spring Boot BOM 来统一版本控制。引入 Starter 后，无需手工添加依赖，M 版本协调由 Boot 自动完成。

### 2. 自动配置类 SPI 机制

Starter 的关键在于自动配置。每个对应 JAR 包中都包含 `META-INF/spring.factories`（或 2.7+ 版本的 `AutoConfiguration.imports`）文件，列出自动配置类列表。Spring Boot 启动时扫描这些 SPI 配置，收集所有候选配置类。

S

### 3. 条件注解控制加载

自动配置类上带有如 `@ConditionalOnClass`、`@ConditionalOnMissingBean`、`@ConditionalOnProperty` 等注解，Spring Boot 在加载配置时会判断当前环境和上下文中是否满足条件，若条件成立则注入相关 Bean，实现功能的“按需自动装配”。

​

### 4. 自动配置顺序与覆盖规则

通过 `@AutoConfigureBefore`、`@AutoConfigureAfter` 和 `@AutoConfigureOrder` 注解，Spring Boot 确保自动配置按照正确顺序加载，且在用户自定义 Bean 存在时优先使用自定义实现，支持优雅覆盖默认行为。

B

### 5. 支持自定义 Starter

开发者可以创建自己的 Starter 模块：

- 引入 `spring-boot-autoconfigure` 和所需依赖；
- 编写 `@Configuration` 自动装配类，并加上条件注解；
- 在 `META-INF/spring.factories` 注册配置类。
