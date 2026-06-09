---
title: 07-JWT-OAuth2-资源服务器与第三方登录
tags:
  - Java
  - SpringBoot
  - SpringSecurity
  - JWT
  - OAuth2
created: 2026-05-09
up: "[[SpringSecurity从0基础到进阶]]"
description: 进阶理解 JWT、OAuth2 Login、OAuth2 Resource Server、issuer-uri、jwk-set-uri、scope 映射、权限转换、授权服务器和资源服务器边界。
---

# 07-JWT-OAuth2-资源服务器与第三方登录

## 1. 先分清几个角色

OAuth2 / OIDC 相关概念容易混。先看角色：

| 名称 | 作用 | 例子 |
|---|---|---|
| Resource Owner | 资源拥有者 | 用户本人 |
| Client | 代表用户访问资源的客户端 | 前端应用、后端应用 |
| Authorization Server | 认证并签发令牌 | Keycloak、Auth0、企业 SSO、Spring Authorization Server |
| Resource Server | 持有受保护 API 的服务 | 订单服务、用户服务 |
| UserInfo Endpoint | 返回用户信息的 OIDC 端点 | 第三方登录后拉取用户资料 |

Spring Security 里常见三类能力：

| 能力 | 用途 |
|---|---|
| OAuth2 Login | 让用户通过第三方或统一身份源登录你的应用 |
| OAuth2 Client | 你的应用作为客户端调用其他 OAuth2 保护的服务 |
| OAuth2 Resource Server | 你的 API 验证 Bearer Token |

## 2. JWT 不是登录协议

JWT 只是一种 token 格式。它可以被 OAuth2 使用，也可以被你自定义登录系统使用。

不要说“我用 JWT 登录”就结束设计。还要说明：

1. 谁签发 JWT？
2. 用什么算法签名？
3. 资源服务器如何拿到公钥或密钥？
4. token 多久过期？
5. 如何刷新？
6. 如何吊销？
7. 权限放在哪里？
8. 前端存在哪里？

## 3. Resource Server 验证 JWT

依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

如果不是通过 starter 聚合，要确保包含 JWT 解码和 JOSE 支持相关依赖。官方文档明确说明，JWT Resource Server 需要 resource server 支持和 `spring-security-oauth2-jose`。

配置授权服务器地址：

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://idp.example.com/issuer
```

安全配置：

```java
@Bean
SecurityFilterChain apiSecurity(HttpSecurity http) throws Exception {
    http
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
        )
        .authorizeHttpRequests(authorize -> authorize
            .requestMatchers("/public/**").permitAll()
            .anyRequest().authenticated()
        )
        .oauth2ResourceServer(oauth2 -> oauth2
            .jwt(Customizer.withDefaults())
        );

    return http.build();
}
```

请求：

```http
GET /api/me HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
```

## 4. issuer-uri 和 jwk-set-uri

`issuer-uri`：

1. 指向授权服务器签发者。
2. Resource Server 会通过标准发现端点找到 JWK Set。
3. 会校验 JWT 的 `iss`、有效期、签名等。
4. 适合标准 OAuth2/OIDC Provider。

`jwk-set-uri`：

1. 直接告诉资源服务器公钥集合地址。
2. 不依赖完整发现端点。
3. 适合授权服务器不支持 discovery 的场景。

示例：

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://idp.example.com/issuer
          jwk-set-uri: https://idp.example.com/.well-known/jwks.json
```

通常优先用 `issuer-uri`。只有 Provider 不标准或启动依赖需要特殊处理时再考虑 `jwk-set-uri`。

## 5. scope 到 authority 的映射

OAuth2 JWT 里常见：

```json
{
  "sub": "alice",
  "scope": "message:read message:write"
}
```

Spring Security Resource Server 默认会把 scope 映射成：

```text
SCOPE_message:read
SCOPE_message:write
```

所以授权时写：

```java
.requestMatchers(HttpMethod.GET, "/messages/**").hasAuthority("SCOPE_message:read")
```

也可以使用官方 DSL 中的 scope 授权辅助方法，具体以项目 Spring Security 版本可用 API 为准。

## 6. 自定义 JWT 权限转换

如果你的 JWT 中权限字段是：

```json
{
  "sub": "alice",
  "permissions": ["user:read", "order:refund"],
  "roles": ["ADMIN"]
}
```

可以自定义 converter：

```java
@Bean
JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtGrantedAuthoritiesConverter scopeConverter = new JwtGrantedAuthoritiesConverter();
    scopeConverter.setAuthorityPrefix("SCOPE_");
    scopeConverter.setAuthoritiesClaimName("scope");

    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(jwt -> {
        List<GrantedAuthority> authorities = new ArrayList<>(scopeConverter.convert(jwt));

        List<String> permissions = jwt.getClaimAsStringList("permissions");
        if (permissions != null) {
            permissions.stream()
                .map(SimpleGrantedAuthority::new)
                .forEach(authorities::add);
        }

        List<String> roles = jwt.getClaimAsStringList("roles");
        if (roles != null) {
            roles.stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                .forEach(authorities::add);
        }

        return authorities;
    });
    return converter;
}
```

配置：

```java
http.oauth2ResourceServer(oauth2 -> oauth2
    .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))
);
```

## 7. 自签 JWT 和标准 Resource Server 的取舍

自签 JWT 的意思是：你的业务系统自己登录、自己签发 token、自己验证 token。

适合：

1. 小型单体系统。
2. 没有统一身份平台。
3. 内部项目。

风险：

1. 容易设计出不安全刷新机制。
2. 密钥轮换、吊销、审计要自己做。
3. 多系统 SSO 困难。

标准 OAuth2/OIDC Provider 适合：

1. 企业统一登录。
2. 多系统共享身份。
3. 微服务资源服务器。
4. 需要标准协议和密钥轮换。

## 8. OAuth2 Login

OAuth2 Login 用于“用户通过第三方登录你的应用”。

依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
```

配置示例：

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          github:
            client-id: your-client-id
            client-secret: your-client-secret
            scope:
              - read:user
              - user:email
```

安全配置：

```java
http
    .authorizeHttpRequests(authorize -> authorize
        .requestMatchers("/", "/login").permitAll()
        .anyRequest().authenticated()
    )
    .oauth2Login(Customizer.withDefaults());
```

用户访问受保护页面时，会跳转到第三方登录。登录成功后，当前应用建立自己的登录状态。

## 9. Resource Server 和 OAuth2 Login 的区别

| 维度 | OAuth2 Login | Resource Server |
|---|---|---|
| 主要目的 | 让用户登录当前应用 | 保护 API |
| 输入 | 浏览器重定向授权码 | `Authorization: Bearer` |
| 登录状态 | 通常是 Session | 通常是无状态 |
| 当前 principal | `OAuth2User` / `OidcUser` | `Jwt` 或 Bearer Token 认证对象 |
| 常见场景 | 管理后台、门户应用 | 微服务 API、前后端分离 API |

## 10. Refresh Token

Access Token 应该短期有效。Refresh Token 用于换新的 Access Token。

设计原则：

1. Access Token 短生命周期，例如 5 到 30 分钟。
2. Refresh Token 长一些，但要可吊销。
3. Refresh Token 轮换，旧 token 使用后失效。
4. 记录设备、IP、UA、签发时间。
5. Refresh Token 泄漏要能强制失效。

如果使用标准 OAuth2 Provider，刷新流程应交给 Provider。Resource Server 只验证 Access Token，不负责刷新。

## 11. 本章小结

记住边界：

1. JWT 是 token 格式，不是完整安全方案。
2. OAuth2 Login 是登录当前应用。
3. OAuth2 Resource Server 是保护 API。
4. Authorization Server 负责签发 token。
5. Resource Server 负责验证 token。
6. scope 默认常映射成 `SCOPE_` 前缀权限。
7. 能用标准 Provider 时，优先用标准 Provider。

