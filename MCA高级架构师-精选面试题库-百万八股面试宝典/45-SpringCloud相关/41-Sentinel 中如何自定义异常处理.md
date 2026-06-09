Sentinel 默认在限流或熔断触发时，会抛出 `BlockException` 或其子类，并由默认处理器快速拒绝请求。如果业务需要更友好的错误响应或额外逻辑，例如统一返回 JSON、记录日志或统计限流情况，就需要自定义异常处理流程。

M

### ​方法一：局部处理（@SentinelResource + blockHandler）

在方法入口使用 `@SentinelResource` 注解指定 `blockHandler`，可对限流、降级等异常单独处理。例如：

```java
@SentinelResource(value = "resourceA", blockHandler = "myBlockHandler")
public String handleA(String arg) { ... }

public String myBlockHandler(String arg, BlockException ex) {
    // 业务降级处理
    return "服务限流，请稍后重试";
}
```

此方式适合需要针对特定资源定制降级策略，每个方法独立定义，灵活控制。适用于少量接口或个别资源处理。  
S

### ​方法二：全局统一异常处理（BlockExceptionHandler 接口）

适用于 Spring Web MVC 或 Spring Cloud Gateway 等场景。你可以实现 `BlockExceptionHandler` 接口，写一个全局异常处理器，并将其注入到 Spring 容器中。例如：

```java
@Component
public class MySentinelExceptionHandler implements BlockExceptionHandler {
    @Override
    public void handle(HttpServletRequest req, HttpServletResponse resp, BlockException ex) throws IOException {
        // 区分 FlowException、DegradeException 等类型
        resp.setStatus(429);
        resp.getWriter().write("限流异常—统一逻辑");
    }
}
```

然后在配置中注册该处理器：`config.setBlockExceptionHandler(new MySentinelExceptionHandler());`。它会覆盖默认行为，实现全局统一响应格式与业务逻辑处理。  
B

### 方法三：系统级异常处理

当既有局部处理器又有全局异常处理器，还可以进一步用系统异常方式统一处理非 `@SentinelResource` 标注资源被限流的情况。这通常用于覆盖缺少 blockHandler 的场景或补充业务逻辑。

执行顺序：局部自定义 > 全局统一处理 > 系统异常处理。即如果局部 blockHandler 不存在，Sentinel 会尝试全局处理器，再fallback到系统默认逻辑。
