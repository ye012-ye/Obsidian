在 Spring Boot 中，条件注解用于根据运行环境或配置动态注册 Bean 或配置类，从而提高应用灵活性。下面从常见注解逐一说明：

首先，**@ConditionalOnClass** 用于检测类路径中是否存在某个类或多个类。如果存在，条件成立，相关 Bean 或配置才会被加载。这背后的检查机制是调用 Condition 接口，由字节码 ASM 库读取注解元数据，再尝试加载指定类，若失败则跳过该配置。 S

相反地，**@ConditionalOnMissingClass** 则仅在指定类缺失时才激活配置，适合提供备用实现方案。

**@ConditionalOnBean** 会在 Spring 容器中已有某个 Bean 定义时触发，用于条件性装配依赖于其他组件的逻辑。例如，只有存在 DataSource 时才注册 Hibernate 配置。

与之相对，**@ConditionalOnMissingBean** 仅在容器内未定义特定 Bean 时触发，经常用于提供默认实现，防止重复创建。 M

**@ConditionalOnProperty** 针对配置文件中的属性进行判断，根据 `application.properties` 或 `application.yml` 中对应属性是否存在、值是否匹配（或 matchIfMissing），有条件地注册 Bean。它常用于控制功能开关。B  
例如：

```java
@Bean
@ConditionalOnProperty(name="feature.x.enabled", havingValue="true", matchIfMissing=false)
public XService xService() { … }
```

**@ConditionalOnExpression** 则允许通过 SpEL 表达式做更复杂的判断，比如结合多个属性或系统参数生成布尔值后进行控制。

此外，还包括如 **@ConditionalOnJava（Java 版本）**、**@ConditionalOnWebApplication** 和 **@ConditionalOnNotWebApplication**（为 Web 或非 Web 应用启用特定组件）等多种条件注解。
