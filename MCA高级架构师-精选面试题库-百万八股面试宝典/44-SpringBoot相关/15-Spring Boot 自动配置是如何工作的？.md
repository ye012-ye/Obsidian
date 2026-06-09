Spring Boot 的自动配置机制依赖于注解驱动和 SPI（服务提供者接口），最核心的流程包括以下几个阶段：

M

### 1. 启用自动配置

在主类上使用 `@SpringBootApplication`，它本质上等同于：

```java
@SpringBootConfiguration  
@EnableAutoConfiguration  
@ComponentScan
```

其中，`@EnableAutoConfiguration` 注解通过 `@Import(AutoConfigurationImportSelector.class)` 将自动配置引入上下文。  
`AutoConfigurationImportSelector` 实现了 `DeferredImportSelector`，用于延迟导入所有候选的自动配置类。

### 2. 识别候选类

启动过程中，`AutoConfigurationImportSelector` 会读取类路径下的 `META-INF/spring.factories`（老版本）或 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`（2.7+）文件，获取自动配置类列表。

### 3. 过滤与排序

获得候选类后，它会进行重复去重，处理用户配置中的 `exclude` / `excludeName`，并根据 `@AutoConfigureBefore`, `@AutoConfigureAfter`, `@AutoConfigureOrder` 等注解排序。

S

### 4. 条件化判断

每个自动配置类上均声明了多重条件，如：

- `@ConditionalOnClass`：判断是否存在某个库；
- `@ConditionalOnMissingBean`：判断是否已存在用户定义的 Bean；
- `@ConditionalOnProperty`：判断配置属性是否满足条件  
  只有所有条件通过，才会将配置类注入 Spring 容器。

### 5. 执行配置

符合条件的自动配置类被注入 BeanFactory，并参与容器刷新过程，即加载其内部 `@Bean` 定义，初始化必要的组件，如数据源、消息中间件、嵌入式服务器等。

### 6. 完整生命周期

最终，Spring Boot 在 `refresh()` 阶段完成 Bean 初始化，启动嵌入式容器，触发 `ApplicationReadyEvent`，执行任何 `CommandLineRunner` 或 `ApplicationRunner`，应用正式就绪。B
