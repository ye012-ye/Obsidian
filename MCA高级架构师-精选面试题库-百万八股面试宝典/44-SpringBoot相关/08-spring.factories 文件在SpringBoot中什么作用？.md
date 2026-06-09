在 Spring Boot 中，`spring.factories` 是实现自动发现、加载扩展组件的重要机制，类似于 Java SPI，但更灵活且集中，其核心作用主要包括以下几个方面：

M

### 1. **自动发现与注册配置类**

启动时，Spring Boot 会扫描所有依赖中 `META-INF/spring.factories` 文件，通过 `SpringFactoriesLoader` 读取并加载指定接口或注解对应的实现类。例如，它会查找所有 `EnableAutoConfiguration` 下列出的自动配置类，并将这些类纳入 Spring 容器管理。这种机制取代了显式注册配置类的繁琐步骤。

### 2. **SPI 式扩展机制**

`spring.factories` 将多个接口与实现类通过一对多的 key–value 形式集中配置，例如 `ApplicationContextInitializer`、`ApplicationListener`、`EnvironmentPostProcessor` 等类型，都可以在此一键扩展。只需在自定义模块中添加该文件，即可实现无侵入式插件注入。

S

### 3. **解耦、模块化与按需装配**

各个模块可以独立提供自己的 `spring.factories`，无需主应用了解实现细节。这进一步实现了模块解耦。借助条件注解（如 `@ConditionalOnClass`、`@ConditionalOnMissingBean` 等），Spring Boot 会在符合条件时再实际加载对应模块，达到“自动装配，按需启用”的目标。

### 4. **启动性能与统一入口**

统一通过读取静态文件而非扫描大量类路径资源，SpringFactoriesLoader 可以快速构建自动配置元数据，从而提升启动效率。同时，也提供一个全局可控的扩展入口。

B

### 示例

```properties
# META-INF/spring.factories
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
  com.example.MyFeatureAutoConfiguration
org.springframework.context.ApplicationListener=com.example.MyStartupListener
```

以上配置会使得：

- `MyFeatureAutoConfiguration` 被纳入自动配置流程。
- `MyStartupListener` 作为监听器自动注册并接收 Spring 应用事件。
