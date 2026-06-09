Spring 提供多种方式注册 Bean，以满足不同场景的需求，常用方式如下：M

#### 1. XML 配置

使用 `<bean>` 元素在 XML 文件中定义 Bean 的 class、属性和依赖注入关系，适合传统项目或集中管理，支持 `<import>` 引入其他配置文件及 `<alias>` 重命名 bean。S

#### 2. 注解扫描

在类上添加 `@Component` 或其衍生注解如 `@Service`、`@Repository`、`@Controller`，配合 `@ComponentScan` 自动扫描并注册。适用于模块化组件开发，可配合 `@Scope`, `@Autowired` 等实现灵活依赖。B

#### 3. JavaConfig（@Configuration + @Bean）

编写配置类，使用 `@Configuration` 标注，再通过 `@Bean` 方法注册 Bean，对象创建更灵活，并支持参数传入、初始化/销毁方法配置等。

#### 4. @Import

在一个 `@Configuration` 类中使用 `@Import(OtherConfig.class)` 引入另一个配置类，实现配置拆分和组合，提升模块化效率。

#### 5. Groovy DSL

通过 Groovy 脚本和 Spring DSL（如 `resources.groovy`）定义 Bean，语法简洁适合动态配置场景，但使用较少。

#### 6. JSR‑330 标准注解

使用标准注解 `@Inject`, `@Named`, `@Singleton`（来自 `jakarta.inject`）替代 Spring 注解，Spring 同样支持扫描注册，但功能略有差异（如 `@Inject` 无 `required` 属性），适合跨容器兼容。
