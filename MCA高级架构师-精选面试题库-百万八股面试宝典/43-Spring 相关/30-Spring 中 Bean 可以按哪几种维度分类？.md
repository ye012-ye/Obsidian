Spring 中 Beans 可从多个角度进行分类，以下为常见分类方法：

#### 1. **按作用域（Scope）**

- **singleton**：默认作用域，整个 Spring 容器中仅有一个实例，适用于无状态Bean，如工具类、服务类。
- **prototype**：每次请求返回新实例，适合有状态对象，如用户会话逻辑。容器只创建，不管理销毁。
- **request / session / global‑session / application / websocket**：仅用于 web 容器中，分别对应单次 HTTP 请求、用户会话、全局会话、应用上下文和 WebSocket 生命周期，适用于 web 场景。

M

#### 2. **按配置方式**

- **XML 配置**：使用 `<bean>` 标签定义 Bean，适合老项目或集中式配置。
- **注解扫描**：通过 `@Component`, `@Service`, `@Repository`, `@Controller` 等注释配合 `@ComponentScan` 自动注册，现代开发主流方式。
- **JavaConfig**：在 `@Configuration` 类中使用 `@Bean` 明确定义，类型安全、易重构。

#### 3. **按生命周期管理**

- **普通 Bean（singleton）**：生命周期由容器管理，从实例化、注入、初始化、销毁皆由容器控制。
- **原型 Bean**：容器只负责创建实例，销毁由调用者负责。
- **作用域代理 Bean（Scoped Proxy）**：当非单例 Bean 注入到单例中时，通过动态代理确保每次访问都是获取目标作用域最新实例。

S

#### 4. **按功能定位**

- **业务 Bean**：封装核心业务逻辑。
- **配置 Bean**：如数据源、事务管理器、消息源等，通过 `@Bean` 或 XML 定义。
- **FactoryBean**：实现 `FactoryBean<T>` 接口，封装复杂对象创建逻辑，Spring 容器调用其 `getObject()` 方法生成 Bean。

B

#### 5. **按依赖注入方式**

- **构造器注入 Bean**：通过构造器注入依赖，确保不可变性、依赖明确，但不支持循环依赖。
- **Setter 注入 Bean**：通过 setter 方法注入，支持可选依赖和循环依赖，但降低依赖明确性。
