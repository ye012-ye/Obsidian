---
title: 04-Controller 与函数式端点
tags:
  - Java
  - WebFlux
  - Controller
  - RouterFunction
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 掌握 WebFlux 的两种编程模型：注解 Controller 与函数式 RouterFunction/HandlerFunction，并理解请求体、响应体、状态码和流式返回。
---

# 04-Controller 与函数式端点

> [!info] 本章抓什么
> WebFlux 写接口有两条路：注解式 Controller 更接近 MVC，函数式端点更适合网关、代理和轻量路由。先会 Controller，再理解 RouterFunction。

## 1. WebFlux 的两种编程模型

Spring Boot 官方文档说明，WebFlux 有两种风格：

1. 注解式：接近 Spring MVC，使用 `@RestController`、`@GetMapping`。
2. 函数式：使用 `RouterFunction` 定义路由，使用 `HandlerFunction` 处理请求。

大多数业务系统优先用注解式，因为团队更熟。网关、轻量服务、强函数式风格项目可以考虑函数式端点。

## 2. 注解式 Controller

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public Mono<ResponseEntity<UserVO>> get(@PathVariable Long id) {
        return userService.getById(id)
                .map(UserVO::from)
                .map(ResponseEntity::ok)
                .defaultIfEmpty(ResponseEntity.notFound().build());
    }

    @GetMapping
    public Flux<UserVO> list() {
        return userService.list().map(UserVO::from);
    }

    @PostMapping
    public Mono<ResponseEntity<UserVO>> create(@Valid @RequestBody Mono<CreateUserRequest> body) {
        return body.flatMap(userService::create)
                .map(UserVO::from)
                .map(user -> ResponseEntity.status(HttpStatus.CREATED).body(user));
    }
}
```

`ResponseEntity<Mono<T>>` 和 `Mono<ResponseEntity<T>>` 的区别：

| 写法 | 含义 |
|---|---|
| `Mono<ResponseEntity<T>>` | 状态码、响应头也可以异步决定 |
| `ResponseEntity<Mono<T>>` | 状态码先确定，body 异步产生 |

生产中更常用 `Mono<ResponseEntity<T>>`，因为 404、201、204 这类状态经常取决于异步结果。

> [!success] 推荐写法
> 当状态码依赖异步查询结果时，优先写 `Mono<ResponseEntity<T>>`。例如查不到返回 404，创建成功返回 201，删除成功返回 204。

## 3. 请求体处理

单对象：

```java
@PostMapping
public Mono<UserVO> create(@RequestBody Mono<CreateUserRequest> body) {
    return body.flatMap(userService::create).map(UserVO::from);
}
```

数组或批量流：

```java
@PostMapping("/batch")
public Flux<UserVO> createBatch(@RequestBody Flux<CreateUserRequest> body) {
    return body.flatMap(userService::create, 16)
            .map(UserVO::from);
}
```

大请求体不要先收集成 `List`，除非你明确知道数据量很小。

## 4. Server-Sent Events

SSE 适合服务端持续推送文本事件：

```java
@GetMapping(value = "/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<ServerSentEvent<String>> events() {
    return Flux.interval(Duration.ofSeconds(1))
            .map(seq -> ServerSentEvent.builder("tick-" + seq)
                    .id(String.valueOf(seq))
                    .event("tick")
                    .build());
}
```

适用场景：

1. AI 流式输出。
2. 实时日志。
3. 任务进度。
4. 后台状态推送。

如果需要双向通信，再考虑 WebSocket。

> [!example] SSE 适配场景
> AI 流式输出、任务进度、实时日志、通知流都很适合 SSE。它比 WebSocket 简单，天然走 HTTP，浏览器端接入成本低。

## 5. 函数式端点

路由配置：

```java
@Configuration
public class UserRoutes {
    @Bean
    RouterFunction<ServerResponse> routes(UserHandler handler) {
        return RouterFunctions.route()
                .GET("/fn/users/{id}", handler::get)
                .GET("/fn/users", handler::list)
                .POST("/fn/users", handler::create)
                .build();
    }
}
```

Handler：

```java
@Component
public class UserHandler {
    private final UserService userService;

    public UserHandler(UserService userService) {
        this.userService = userService;
    }

    public Mono<ServerResponse> get(ServerRequest request) {
        Long id = Long.valueOf(request.pathVariable("id"));
        return userService.getById(id)
                .flatMap(user -> ServerResponse.ok().bodyValue(UserVO.from(user)))
                .switchIfEmpty(ServerResponse.notFound().build());
    }

    public Mono<ServerResponse> list(ServerRequest request) {
        return ServerResponse.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(userService.list().map(UserVO::from), UserVO.class);
    }

    public Mono<ServerResponse> create(ServerRequest request) {
        return request.bodyToMono(CreateUserRequest.class)
                .flatMap(userService::create)
                .flatMap(user -> ServerResponse.status(HttpStatus.CREATED).bodyValue(UserVO.from(user)));
    }
}
```

## 6. 什么时候用哪种

| 情况 | 推荐 |
|---|---|
| 常规后台 API | 注解式 Controller |
| 团队从 MVC 迁移 | 注解式 Controller |
| 网关、代理、轻量转发 | 函数式端点 |
| 希望路由集中管理 | 函数式端点 |
| 复杂业务系统 | 注解式更易读 |

## 7. Controller 层原则

1. 不写阻塞调用。
2. 不手动 `subscribe()`。
3. 不把业务逻辑全堆在 `flatMap` 里。
4. 参数校验、DTO 转换、状态码处理可以放 Controller。
5. 跨接口复用逻辑放 Service。

> [!warning] 可读性提醒
> 不要把十几层 `flatMap` 全塞在 Controller。响应式代码不是越链式越高级，业务分支复杂时拆 Service 方法会更好维护。
