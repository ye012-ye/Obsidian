Spring MVC 基于前端控制器（Front Controller）模式，由 `DispatcherServlet` 负责整个请求处理流程，其步骤如下：

​

M

### 1. 接收请求

客户端（浏览器/客户端）发送 HTTP 请求，首先拦截至部署在服务器（如 Tomcat）中的 `DispatcherServlet`，该 Servlet 注册于 `/` 或特定路径映射上。

### 2. 查找处理器（HandlerMapping）

DispatcherServlet 接收到请求后，将其委托给 HandlerMapping 组件（如 `RequestMappingHandlerMapping`），根据 URL、HTTP 方法等匹配对应的 Controller 方法。

S

### 3. 执行处理器（HandlerAdapter + Controller）

找到目标 handler（通常为某个 controller 方法）后，由 HandlerAdapter（如 `RequestMappingHandlerAdapter`）负责调用方法，同时解析方法参数如 `@RequestParam`、`@PathVariable`、`@RequestBody` 等。

### 4. 返回模型和视图（ModelAndView）

Controller 执行业务逻辑后，返回一个 `ModelAndView` 或视图名与模型数据。DispatcherServlet 接收该返回结果，用于后续渲染流程。

B

### 5. 视图解析与渲染（ViewResolver + View）

DispatcherServlet 调用 ViewResolver 将逻辑视图名转换为实际视图（如 JSP、Thymeleaf、JSON 序列化器等）。随后，用模型数据调用 View 渲染输出 HTML 或 JSON，并返回 HTTP 响应。

### 6. 响应返回

最终，`DispatcherServlet` 将渲染后的视图内容写入 HTTP 响应体，返回给客户端，完成一次完整请求生命周期。
