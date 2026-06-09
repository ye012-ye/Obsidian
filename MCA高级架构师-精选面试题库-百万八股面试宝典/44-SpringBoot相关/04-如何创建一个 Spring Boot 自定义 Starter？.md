自定义 Starter 的核心在于打包一个可复用的功能模块，并通过自动配置机制让主应用「开箱即用」地加载。 按照如下方式可以实现：

### 1. 创建 Starter 工具项目

新建一个 Maven/Gradle 项目，结构标准，如 `src/main/java` 和 `src/main/resources`，并在 `pom.xml` 中添加必要依赖：`spring-boot-autoconfigure` + `spring-boot-configuration-processor`（用于属性元数据生成）。

M

### 2. 编写自动配置类

新建一个类用 `@Configuration` 或 Spring Boot 3 中的 `@AutoConfiguration` 标注，在类中定义 Bean，并使用条件注解（如 `@ConditionalOnClass`, `@ConditionalOnProperty`）控制装配逻辑。例如：

```java
@AutoConfiguration
public class MyStarterAutoConfig {
    @Bean
    @ConditionalOnMissingBean
    public MyService myService(CustomProperties props) {
        return new MyService(props.getPrefix());
    }
}
```

这样只有在类路径存在相关依赖，且应用未定义同名 Bean 时，`MyService` 才被注册。

### 3. 定义配置属性类

如果提供可配置项，应添加一个 `@ConfigurationProperties(prefix="xxx")` 类，例如：

```java
@ConfigurationProperties("mystarter")
public class StarterProperties {
    private String prefix = "hello";
    // getter/setter
}
```

这样用户可以在主应用通过 `mystarter.prefix=…` 调整行为。

S

### 4. 在 META-INF 声明自动配置

Spring Boot 会读取下列文件查找 Starter 放出的自动配置：

- `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`（Spring Boot 2.7+）
- 或老版本中 `META-INF/spring.factories`

文件示例：

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.MyStarterAutoConfig
```

Spring 启动时使用 `SpringFactoriesLoader` 自动加载这些配置类，也是 Starter 被识别的关键机制。

### 5. 可选：提供默认属性文件

若 Starter 有默认配置，可新增 `mystarter-defaults.properties` 并通过 `@PropertySource` 或将其放入 `/config` 下。这样主应用无需手动配置也能正常运行。

B

### 6. 打包发布整合应用

执行 `mvn clean install` 之后，其他项目只需引入以下依赖即可自动生效：

```xml
<dependency>
  <groupId>com.example</groupId>
  <artifactId>my-spring-boot-starter</artifactId>
  <version>1.0.0</version>
</dependency>
```

启动后，Spring Boot 会依据 classpath 识别并加载你的自动配置类；可通过 `application.properties` 中的 `mystarter.*` 修改运行行为。
