Feign 框架通过自定义 `RequestInterceptor` 实现认证信息（如 JWT 或 OAuth2 Token）的自动传递，通常包括以下关键步骤：M

### 1. 自定义 Feign 拦截器

实现 `RequestInterceptor` 接口，在 `apply(RequestTemplate template)` 方法中：

- 从当前线程的 `SecurityContextHolder` 或 HTTP 请求头（`Authorization`）读取认证 Token；
- 将 Token 注入 Feign 请求头，例如 `template.header("Authorization", "Bearer " + token)`。这样每次调用 Feign 接口时，都会自动带上认证信息。  
  此机制可用于用户上下文的传递，也支持 OAuth2 客户端凭证模式，在拦截器中调用授权服务获取 Token 并注入请求头。

### 2. 支持异步或断路器场景下的上下文传播

Feign 与 Hystrix 或 Resilience4j 集成时，可能会在异步子线程中执行调用，此时默认的 `SecurityContextHolder` 不会跨线程传递。  
常用的做法是：使用 Spring 提供的 `DelegatingSecurityContextRunnable` 或 `DelegatingSecurityContextCallable` 来包装异步任务，或配置安全上下文传播策略，以确保拦截器可从子线程中正常读取用户身份。

### 3. 基于 OAuth2 客户端凭证的 Token 获取

对于服务间调用（无用户上下文），可使用 OAuth2 Client Credentials 模式。通过 Spring Security 的 `OAuth2AuthorizedClientService` 获取访问令牌，并在 Feign 拦截器中注入 `Authorization` header。这样服务 A 可作为客户端认证调用服务 B，无需依赖当前 HTTP 请求上下文。

S
