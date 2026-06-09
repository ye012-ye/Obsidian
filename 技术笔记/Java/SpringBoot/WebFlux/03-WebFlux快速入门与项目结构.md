---
title: 03-WebFlux 快速入门与项目结构
tags:
  - Java
  - SpringBoot
  - WebFlux
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 从零创建 Spring Boot WebFlux 项目，理解 starter、自动配置、默认 Netty、应用类型选择、分层结构和最小 CRUD 示例。
---

# 03-WebFlux 快速入门与项目结构

> [!info] 本章抓什么
> 这一章目标是跑通一个真正的 WebFlux 项目，并知道目录该怎么分层。重点看 starter、应用类型、Controller/Service/Repository 的返回值如何保持响应式。

## 1. Maven 依赖

最小依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

只引入 `spring-boot-starter-webflux` 时，Spring Boot 默认使用 Reactor Netty。不要同时引入 `spring-boot-starter-web`，否则 Spring Boot 默认会按 MVC 应用配置。

如果确实两个 starter 都存在，可以强制指定：

```properties
spring.main.web-application-type=reactive
```

> [!warning] starter 提醒
> 如果你只是想在 MVC 项目里用 `WebClient`，可以引入 WebFlux；但如果你想让整个应用按 WebFlux 跑，就要确认没有被 `spring-boot-starter-web` 默认切回 MVC。

## 2. 推荐项目结构

```text
src/main/java/com/example/webflux
├── WebfluxDemoApplication.java
├── api
│   ├── UserController.java
│   └── UserRoutes.java
├── application
│   └── UserService.java
├── domain
│   ├── User.java
│   └── UserStatus.java
├── infrastructure
│   ├── UserRepository.java
│   └── RemoteAccountClient.java
└── support
    ├── GlobalErrorHandler.java
    └── WebFluxConfig.java
```

分层要点：

1. Controller 或 Router 只做 HTTP 协议适配。
2. Service 返回 `Mono` 或 `Flux`，不要在内部 `block()`。
3. Repository 尽量使用响应式驱动，如 R2DBC、Reactive MongoDB。
4. 调第三方 HTTP 服务用 `WebClient`。
5. 需要兼容老阻塞库时，明确隔离到 `boundedElastic`。

> [!success] 分层原则
> Controller 负责 HTTP，Service 负责编排业务流，Repository/Client 负责外部 I/O。响应式类型最好从入口一路传到底，不要中途拆成同步对象再塞回 `Mono`。

## 3. 最小启动类

```java
package com.example.webflux;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WebfluxDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(WebfluxDemoApplication.class, args);
    }
}
```

## 4. 一个内存版 Repository

```java
package com.example.webflux.infrastructure;

import com.example.webflux.domain.User;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class UserRepository {
    private final Map<Long, User> store = new ConcurrentHashMap<>();

    public UserRepository() {
        store.put(1L, new User(1L, "张三"));
        store.put(2L, new User(2L, "李四"));
    }

    public Mono<User> findById(Long id) {
        return Mono.justOrEmpty(store.get(id));
    }

    public Flux<User> findAll() {
        return Flux.fromIterable(store.values());
    }

    public Mono<User> save(User user) {
        store.put(user.id(), user);
        return Mono.just(user);
    }

    public Mono<Void> deleteById(Long id) {
        store.remove(id);
        return Mono.empty();
    }
}
```

领域对象：

```java
package com.example.webflux.domain;

public record User(Long id, String name) {
}
```

## 5. Service 写法

```java
package com.example.webflux.application;

import com.example.webflux.domain.User;
import com.example.webflux.infrastructure.UserRepository;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public Mono<User> getById(Long id) {
        return userRepository.findById(id)
                .switchIfEmpty(Mono.error(new IllegalArgumentException("用户不存在: " + id)));
    }

    public Flux<User> list() {
        return userRepository.findAll();
    }

    public Mono<User> create(User user) {
        return userRepository.save(user);
    }
}
```

## 6. Controller 写法

```java
package com.example.webflux.api;

import com.example.webflux.application.UserService;
import com.example.webflux.domain.User;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public Mono<User> get(@PathVariable Long id) {
        return userService.getById(id);
    }

    @GetMapping
    public Flux<User> list() {
        return userService.list();
    }

    @PostMapping
    public Mono<User> create(@RequestBody Mono<User> body) {
        return body.flatMap(userService::create);
    }
}
```

注意 `@RequestBody Mono<User>`：请求体读取本身也是异步的。简单场景也可写 `@RequestBody User user`，但深入 WebFlux 后建议理解请求体流化处理。

## 7. 配置文件

```yaml
server:
  port: 8080

spring:
  main:
    web-application-type: reactive
  webflux:
    problemdetails:
      enabled: true

logging:
  level:
    reactor.netty.http.client: INFO
    org.springframework.web.reactive: INFO
```

## 8. 启动后验证

```bash
curl http://localhost:8080/users
curl http://localhost:8080/users/1
curl -X POST http://localhost:8080/users ^
  -H "Content-Type: application/json" ^
  -d "{\"id\":3,\"name\":\"王五\"}"
```

## 9. 入门阶段最容易犯的错

1. 同时引入 `spring-boot-starter-web` 和 `spring-boot-starter-webflux`，结果应用不是 WebFlux。
2. Controller 返回 `List<T>`，Service 内部到处 `block()`。
3. 用 JPA 以为就是响应式数据库访问。
4. 在响应式链路里写复杂可变状态，导致并发问题。
5. 看到异步就手动 `subscribe()`，导致请求还没处理完 HTTP 响应就结束。

> [!danger] 入门最危险误区
> 在 WebFlux Controller 里手动 `subscribe()` 通常是错的。框架会负责订阅返回的 `Mono` 或 `Flux`，你手动订阅反而可能让异常、事务、响应写出都脱离请求生命周期。
