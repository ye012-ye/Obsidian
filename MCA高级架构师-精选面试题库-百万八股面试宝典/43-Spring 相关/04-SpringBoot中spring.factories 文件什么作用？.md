Spring Boot 利用 `spring.factories` 文件实现一种轻量级 SPI（Service Provider Interface）机制，这使得框架可以通过约定配置的方式实现自动扩展：

M

### 1. SPI 实现机制

- 在 `META-INF/spring.factories` 中使用 **接口全限定名**作为键，将多个实现类的**实现全限定名**作为值（逗号分隔）。
- 启动时，SpringBoot通过 `SpringFactoriesLoader.loadFactoryNames(...)` 扫描和加载所有位于 classpath 下的 `spring.factories` 条目。

S

### 2. 支持的扩展类型

常见利用入口包括：

- `EnableAutoConfiguration` **子类**：自动导入配置类，实现默认功能；
- `ApplicationListener`：监听多种生命周期事件；
- `ApplicationContextInitializer`：在容器刷新前执行预处理；
- 也支持自定义接口：如只需新增实现类并在文件中声明即可自动生效，无需代码修改。

B

总结：`spring.factories` 文件是 Spring Boot SPI 的核心，通过约定式配置实现自动扩展和功能加载。开发者只需在 `META-INF/spring.factories` 中声明接口与实现，即可接入自动配置、生命周期监听等机制，无需代码耦合。
