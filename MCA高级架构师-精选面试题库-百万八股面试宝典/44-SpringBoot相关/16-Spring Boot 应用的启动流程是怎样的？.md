Spring Boot 的启动可分为以下几个阶段：M

1. **执行 main 方法**  
   应用入口是带有 `@SpringBootApplication` 注解的主类，它执行 `SpringApplication.run(...)`。这一调用首先根据classpath 判断应用类型（Servlet、Reactive 或 None），并解析启动类及 `spring.factories` 中配置的初始化器和监听器。
2. **准备环境与监听器**  
   `run()` 创建 `SpringApplicationRunListener` 实例，负责生命周期事件管理。接着建立 `Environment`，处理配置文件、命令行参数及系统属性，并发布准备事件。
3. **创建 ApplicationContext**  
   根据应用类型，选择合适的上下文实现，如 `AnnotationConfigServletWebServerApplicationContext`（网页类型）或非网页类型上下文。S
4. **刷新上下文（refresh）**  
   调用 `refreshContext()` 然后 `refresh()`，启动 `AbstractApplicationContext`。该流程中执行如下活动：

- 注册 BeanFactory 的增强器（PostProcessors）
- 扫描 `@Component`、`@Configuration`、`@EnableAutoConfiguration` 注解，加载自动配置类
- 实例化并填充 Bean（包括 `@Autowired` 注入）
- 触发 Bean 的初始化前后置逻辑。

5. **启动内嵌容器（如适用）**  
   若为 Web 应用，自动配置会创建并启动如 Tomcat 或 Jetty 的嵌入式 Servlet 容器，使服务可监听 HTTP 请求。B
6. **触发后处理器与完成事件**  
   容器刷新后，Spring 会运行所有 `ApplicationRunner`／`CommandLineRunner`，再发布 `ApplicationReadyEvent`，标志服务已完成启动并准备就绪。
