Spring Boot 提供了多种机制用于读取配置属性，根据场景的不同选择合适方式，可提升可维护性、类型安全与灵活度。以下是六种主流方法:

M

### 1. `Environment` 或 `PropertyResolver`

可直接注入 `Environment`（或更通用的 `PropertyResolver`），通过 `.getProperty("key")` 获取单个属性值。适用于运行时临时获取配置，如控制流程逻辑。它反映了最原始的底层机制，属性来源包括：默认属性、外部文件、环境变量、命令行等。

### 2. `@Value` 注解

直接在字段、方法参数或构造器中注入单个属性：

```java
@Value("${my.prop:defaultValue}")
private String myProp;
```

适合快速获取零散配置，支持设置默认值和 SpEL 表达式。使用轻便，但会分散配置点，不适用于大量属性组合绑定。

S

### 3. `@ConfigurationProperties` 注解

通过注解标记一个 POJO 类，Spring 自动将同前缀配置值绑定至类属性，适用于批量、结构化配置绑定。支持类型转换（如 `Duration`, `List`, `Map`）与校验（JSR-303），代码清晰、易于测试。

### 4. `@PropertySource` / `@PropertySources`

用于加载 `application.properties` 之外的自定义属性文件：

```java
@PropertySource("classpath:custom.properties")
```

仅支持 `.properties` 默认格式，如需 `.yml`，需实现自定义 `PropertySourceFactory`。适用于从特定文件加载补充配置。

B

### 5. `YamlPropertiesFactoryBean`

可用在配置类中显示配置 `.yml` 文件：

```java
@Bean
public static PropertySourcesPlaceholderConfigurer yamlConfigurer() { … }
```

可配合 `@Value` 或 `Environment` 使用，适用于非 Spring Boot 默认 `application.yml` 中读取配置。

### 6. 原生 Java `Properties` 读取

直接通过 `Properties.load(...)` 从任意资源读取配置，适用于完全自定义场景。这种方式脱离 Spring IOC，用于特定资源或独立执行模块时使用。灵活但需手动管理。

### 对比

|  |  |  |  |
| --- | --- | --- | --- |
| **方式** | **场景** | **优势** | **劣势** |
| Environment | 随时获取、逻辑判断 | 灵活、无需注解 | 分散、无类型检查 |
| @Value | 单值注入 | 简洁直观 | 无结构化、注解过多 |
| @ConfigurationProperties | 结构化配置 | 类型安全、易测试 | 类较多需配置支持 |
| @PropertySource | 加载额外 `.properties` | 指定文件、集中加载 | 不支持 YAML 需扩展 |
| YamlPropertiesFactoryBean | 专门加载 yaml 文件 | 手动配置灵活 | 配置较繁琐 |
| 原生 Properties | 非 Spring 环境或独立模块 | 自主可控 | 缺少 Spring 优惠机制 |
