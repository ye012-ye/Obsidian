`@SpringBootApplication` 是一个组合注解，它整合了三个关键功能，使 Spring Boot 的启动和配置变得简洁且高效：

### 1. `@SpringBootConfiguration`

- 相当于 `@Configuration` 的 Spring Boot 特化，用来表明该类是一个配置类。
- 它告诉 Spring IoC 容器该类可以提供 bean 定义来源。

M

### 2. `@EnableAutoConfiguration`

- 启用自动配置机制，Spring Boot 根据类路径中的依赖（如 Spring MVC、Thymeleaf、JPA 等）自动配置相应的 beans 与默认行为。
- 配置通过读取 `META-INF/spring.factories` 中的 `@Configuration` 类，并根据条件注解（如 `@ConditionalOnClass`）加载或忽略配置。

S

### 3. `@ComponentScan`

- 启用组件扫描，从该类所在包及其子包中自动发现并注册 `@Component`, `@Service`, `@Repository`, `@Controller` 等注解的类。
- 这使你无需手动配置扫描路径，只需将主类放在根包即可 。

B
