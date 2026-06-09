---
title: 06-会话-CSRF-CORS-安全响应头
tags:
  - Java
  - SpringBoot
  - SpringSecurity
  - CSRF
  - CORS
created: 2026-05-09
up: "[[SpringSecurity从0基础到进阶]]"
description: 理解 Spring Security 中的 Session 会话管理、CSRF 防护、CORS 跨域、安全响应头、Remember-me、并发登录控制和前后端分离常见取舍。
---

# 06-会话-CSRF-CORS-安全响应头

## 1. Session 会话管理

Spring Security 的表单登录默认通常使用 Session 保存登录状态。认证成功后，当前用户的 `Authentication` 会被保存，后续请求通过 Session 恢复。

常见配置：

```java
http.sessionManagement(session -> session
    .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
);
```

策略：

| 策略 | 含义 |
|---|---|
| `ALWAYS` | 总是创建 Session |
| `IF_REQUIRED` | 需要时创建，传统 Web 常用 |
| `NEVER` | 不主动创建，但如果已有 Session 可以用 |
| `STATELESS` | 不创建也不使用 Session，JWT API 常用 |

## 2. Session 固定攻击

Session 固定攻击是攻击者先拿到一个 Session ID，再诱导用户用这个 Session 登录，从而复用用户登录态。

Spring Security 默认会做 Session fixation protection，登录成功后更换 Session ID。

配置示例：

```java
http.sessionManagement(session -> session
    .sessionFixation(sessionFixation -> sessionFixation.migrateSession())
);
```

常见选项：

| 选项 | 含义 |
|---|---|
| `migrateSession()` | 创建新 Session 并迁移属性 |
| `newSession()` | 创建新 Session，不迁移旧属性 |
| `changeSessionId()` | Servlet 3.1+ 直接改 Session ID |
| `none()` | 不做保护，不建议 |

## 3. 并发登录控制

限制同一账号最多登录数：

```java
http.sessionManagement(session -> session
    .maximumSessions(1)
    .maxSessionsPreventsLogin(false)
);
```

含义：

1. `maximumSessions(1)`：同一用户最多一个 Session。
2. `maxSessionsPreventsLogin(false)`：新登录踢掉旧登录。
3. 如果设置为 `true`：旧登录存在时拒绝新登录。

前后端分离或 JWT 场景中，如果要控制并发登录，通常需要服务端 token 存储、用户 token 版本号或设备表。

## 4. CSRF 是什么

CSRF 是跨站请求伪造。它主要针对“浏览器自动携带 Cookie”的认证方式。

例子：

1. 用户登录银行网站，浏览器保存银行 Cookie。
2. 用户不登出，又打开攻击者页面。
3. 攻击者页面自动提交一个转账表单到银行。
4. 浏览器自动带上银行 Cookie。
5. 如果银行只认 Cookie 且没有 CSRF Token，就可能误认为是用户本人操作。

Spring Security 默认启用 CSRF 防护。

## 5. 什么时候不能随手关闭 CSRF

不要关闭：

1. 服务端渲染页面。
2. 表单登录 + Cookie Session。
3. 浏览器会自动携带身份 Cookie 的系统。
4. 管理后台。

可以考虑关闭：

1. 纯 REST API。
2. 不使用 Cookie 表示身份。
3. 每次请求都用 `Authorization: Bearer <token>`。
4. 非浏览器客户端调用。

但更准确的说法是：

> 是否需要 CSRF 防护，取决于浏览器是否会在跨站请求中自动携带认证凭证，而不是取决于你的接口是不是 JSON。

## 6. CSRF Token

服务端渲染表单里通常要带隐藏字段：

```html
<input type="hidden" name="_csrf" value="token-value">
```

如果使用 Thymeleaf 并集成 Spring Security，很多表单会自动处理。

AJAX 可以通过响应暴露 token，然后请求头带回：

```http
X-CSRF-TOKEN: token-value
```

配置 Cookie 存储 CSRF Token：

```java
http.csrf(csrf -> csrf
    .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
);
```

`withHttpOnlyFalse()` 让前端 JS 可以读取 CSRF Cookie，并放入请求头。它不是给身份 Cookie 用的，而是给 CSRF Token 用的。

## 7. 前后端分离里的 CSRF 取舍

方案一：JWT 放 Authorization 头，后端无 Session。

```java
http
    .csrf(AbstractHttpConfigurer::disable)
    .sessionManagement(session -> session
        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
    );
```

适合移动端、开放 API、微服务资源接口。

方案二：Cookie Session + SPA。

```java
http
    .csrf(csrf -> csrf
        .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
    );
```

适合同域部署或 BFF 架构。前端需要读取 CSRF Token 并放到请求头。

方案三：Access Token 放内存，Refresh Token 放 HttpOnly Cookie。

需要更完整设计：

1. Access Token 短期有效。
2. Refresh Token 使用 HttpOnly + Secure + SameSite。
3. 刷新接口考虑 CSRF。
4. 支持刷新令牌轮换和失效。

## 8. CORS 配置

Spring Security 需要和 Spring MVC 的 CORS 配置协同。

推荐提供 `CorsConfigurationSource`：

```java
@Bean
CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(List.of("http://localhost:3000"));
    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-CSRF-TOKEN"));
    configuration.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

启用：

```java
http.cors(Customizer.withDefaults());
```

注意：

1. 带 Cookie 时 `allowedOrigins` 不能是 `*`。
2. 预检请求是 `OPTIONS`。
3. 浏览器报 CORS 时，不一定是接口没执行，可能是响应头不符合浏览器要求。

## 9. 安全响应头

Spring Security 默认会添加一些安全响应头。常见头：

| Header | 作用 |
|---|---|
| `X-Content-Type-Options: nosniff` | 防止 MIME 嗅探 |
| `X-Frame-Options` | 降低点击劫持风险 |
| `Cache-Control` | 避免缓存敏感页面 |
| `Strict-Transport-Security` | 强制 HTTPS |
| `Content-Security-Policy` | 限制页面可加载资源 |

配置 CSP 示例：

```java
http.headers(headers -> headers
    .contentSecurityPolicy(csp -> csp
        .policyDirectives("default-src 'self'; script-src 'self'")
    )
);
```

如果要允许 iframe：

```java
http.headers(headers -> headers
    .frameOptions(frame -> frame.sameOrigin())
);
```

不要为了让某个页面能嵌入就直接关闭全部安全头。

## 10. Remember-me

Remember-me 用于关闭浏览器后仍保持登录。

```java
http.rememberMe(remember -> remember
    .key("change-this-secret")
    .tokenValiditySeconds(7 * 24 * 60 * 60)
);
```

生产建议：

1. 使用强随机 key。
2. 重要操作仍要求重新认证。
3. 可使用持久化 token 存储。
4. 登出时清理 remember-me cookie。

## 11. 本章小结

选择依据：

| 场景 | 推荐 |
|---|---|
| 服务端页面后台 | Session + CSRF + formLogin |
| 同域 SPA + BFF | Cookie Session + CSRF Token |
| 纯 API + 移动端 | Stateless + Bearer Token |
| 第三方 SSO | OAuth2 Login 或 OIDC |
| 微服务资源接口 | OAuth2 Resource Server + JWT |

最容易踩的坑：

1. POST 403 误以为没权限，其实是 CSRF。
2. 跨域请求失败误以为后端接口错，其实是 CORS 响应头。
3. JWT 项目忘记设置 `SessionCreationPolicy.STATELESS`。
4. Cookie 跨域忘记 SameSite、Secure、allowCredentials。
5. 为了图快关闭所有安全头。

