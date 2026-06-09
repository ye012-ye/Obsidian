Spring MVC 架构中，常见一个 “根容器（Root ApplicationContext） + 多个子容器（DispatcherServlet 的 WebApplicationContext）” 的层级结构，这种设计背后的原因如下：

#### 1. **职责分层，职责清晰**

- **根容器** 加载服务层（Service）和数据访问层（DAO）等核心组件；
- **子容器** 专门管理 Web 层（Controller、视图解析器、拦截器等）。

- 子容器可以访问父容器 bean，但父容器看不到子容器中的 bean。

#### 2. **模块化隔离，避免污染**

- 支持多个 `DispatcherServlet` 实例，各自拥有独立 Web bean 集合；
- 根容器组件共享但不会相互干扰，适合大型应用中多个模块并存。

#### 3. **Bean 重用与覆盖**

- 子容器可直接重用父容器定义的 bean（如通用 Service/DAO）；
- 必要时，子容器也允许覆盖父容器的 bean 配置（例如热切换、测试替换）。

#### 4. **配置清晰，便于测试**

- 根级通用组件与子级 Web 配置分离，部署、维护更清晰；
- 测试时可以仅加载根容器或子容器，避免加载无关配置，提高速度和稳定性。

### **启动流程（以 web.xml 或 Java Config 为例）**

```xml
<!-- 在 web.xml 或 WebApplicationInitializer 中配置： -->
<listener>
  <listener-class>ContextLoaderListener</listener-class>  <!-- 加载根容器 -->
</listener>

<servlet>
  <servlet-name>dispatcher</servlet-name>
  <servlet-class>DispatcherServlet</servlet-class>      <!-- 加载对应子容器 -->
  <init-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>/WEB-INF/dispatcher-config.xml</param-value>
  </init-param>
</servlet>
```

这样启动后：

- Controller 可以通过 `@Autowired` 注入 Service/DAO；
- Service 层无法访问 Controller，确保职责层次清晰。
