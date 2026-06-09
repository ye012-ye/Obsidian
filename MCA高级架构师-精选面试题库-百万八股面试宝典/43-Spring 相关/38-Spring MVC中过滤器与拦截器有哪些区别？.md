Filter 和 Interceptor 均用于请求处理链，但它们存在本质上的不同，能体现对 Java Web 运行机制的深入理解。M

#### 1. 来源不同

- **过滤器（Filter）** 属于 **Servlet 规范**（`javax.servlet.Filter`），由 Servlet 容器（如 Tomcat）管理，需要在 `web.xml` 或 `@WebFilter` 中配置。
- **拦截器（Interceptor）** 属于 **Spring MVC** 框架（`HandlerInterceptor`），由 Spring 容器管理，通过 `WebMvcConfigurer` 注册 。

S

#### 2. 执行时机

- **Filter** 总是在请求进入 Servlet 前以及响应离开时执行，作用于整个 web 应用范畴，包括静态资源。
- **Interceptor** 发生在 DispatcherServlet 与 Controller 之间，执行时机为 `preHandle → postHandle → afterCompletion`，仅对 Spring MVC 请求有效。

B

#### 3. 能力与灵活性

- **Filter** 能彻底操作 `ServletRequest` 和 `ServletResponse`，可修改请求、封装请求对象、控制请求是否继续执行。它适合处理诸如请求编码、压缩、静态资源缓存、XSS 过滤等底层功能。
- **Interceptor** 拥有细粒度控制，能够访问 `HandlerMethod` 和 `ModelAndView`，便于在 Controller 级别进行业务逻辑判断、系统日志或局部权限校验，但不能修改原始请求对象。

### 总结

- **Filter** 更底层，全局作用于容器生命周期，功能强大但粒度粗，适用于编码、安全、压缩、request/response 包装等任务。
- **Interceptor** 更高层，适合业务逻辑相关拦截，如鉴权、日志记录、接口限流、模型调整等，且依赖于 Spring MVC 框架。
