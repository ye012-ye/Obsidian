---
title: 09-WebFlux 面试题 与避坑清单
tags:
  - Java
  - WebFlux
  - 面试
  - 最佳实践
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 汇总 WebFlux 高频面试题、项目选型回答、生产避坑、代码审查清单和从入门到大神的复习路线。
---

# 09-WebFlux 面试题 与避坑清单

> [!info] 本章抓什么
> 面试回答 WebFlux，不要只背“异步非阻塞”。高分回答要能讲清适用场景、底层模型、常见坑、为什么不用、以及生产上怎么兜住风险。

## 1. 高频面试题

### 1. WebFlux 和 Spring MVC 有什么区别

Spring MVC 主要基于 Servlet 编程模型，典型方式是一个请求由一个工作线程处理，遇到 JDBC、HTTP 等 I/O 时线程阻塞等待。WebFlux 基于 Reactive Streams，默认使用 Reactor Netty，可通过少量事件循环线程处理大量连接，I/O 等待期间不占用工作线程。WebFlux 支持背压，适合 I/O 密集、流式响应、长连接、网关等场景。

### 2. Mono 和 Flux 区别是什么

`Mono<T>` 表示 0 或 1 个异步结果，常用于单对象查询、创建结果、删除完成信号。`Flux<T>` 表示 0 到 N 个异步结果，常用于列表、数据流、SSE、WebSocket 消息流。

### 3. 为什么 WebFlux 不能随便 block

`block()` 会把异步非阻塞链路变成同步等待。如果它发生在 Netty 事件循环线程上，会阻塞该线程处理其他连接，导致吞吐下降、延迟上升，严重时拖垮整个实例。WebFlux 中应通过 `flatMap`、`zip` 等操作符组合异步结果。

### 4. map 和 flatMap 区别

`map` 用于同步转换，输入一个值，输出一个普通值。`flatMap` 用于异步转换，输入一个值，输出 `Mono` 或 `Flux`，并自动展开。

```java
userMono.map(UserVO::from);
userMono.flatMap(user -> orderRepository.findByUserId(user.id()));
```

### 5. publishOn 和 subscribeOn 区别

`subscribeOn` 影响订阅源头在哪个调度器上执行，通常用于包装阻塞源头。`publishOn` 影响它后续操作在哪个调度器上执行，位置很重要。无法避免的阻塞 I/O 通常用 `Schedulers.boundedElastic()` 隔离。

### 6. WebFlux 能不能用 JPA

技术上可以调用，但 JPA/JDBC 是阻塞模型，不是真正响应式。迁移期可以用 `Mono.fromCallable(...).subscribeOn(Schedulers.boundedElastic())` 隔离，但长期要么保留 MVC/虚拟线程，要么切换 R2DBC、Reactive MongoDB 等响应式驱动。

### 7. WebFlux 适合哪些场景

适合高并发 I/O、服务编排、API Gateway、SSE、WebSocket、实时推送、流式 AI 响应、响应式数据库访问。不适合简单 CRUD、CPU 密集计算、阻塞依赖很多且无法替换的系统。

## 2. 项目选型回答模板

可以这样回答：

> 我不会因为 WebFlux 高级就默认使用它。先看链路是不是 I/O 密集，下游客户端和数据库驱动是否支持非阻塞，团队是否熟悉 Reactor，压测是否证明线程占用和吞吐有收益。如果只是 JPA CRUD 或团队维护成本更关键，我会优先 Spring MVC 或 Java 21 虚拟线程。如果是网关、SSE、WebSocket、远程服务聚合、流式响应，我会考虑 WebFlux。

> [!success] 面试表达技巧
> 先讲收益，再讲边界，最后讲落地经验。能主动说出“不适合的场景”，反而更像真的做过项目，而不是只背过概念。

## 3. 代码审查清单

看到这些要警惕：

```java
.block()
.toFuture().get()
Thread.sleep(...)
Files.readAllBytes(...)
RestTemplate
JdbcTemplate
JpaRepository
collectList()
flatMap(x -> call(x))
subscribe()
```

逐项判断：

1. 是否发生在事件循环线程。
2. 是否有数据量上限。
3. 是否有超时。
4. 是否限制并发。
5. 是否破坏事务或请求生命周期。
6. 是否有替代的响应式客户端。

> [!danger] 看到就追问
> `block()`、`subscribe()`、无限制 `flatMap()`、无超时 WebClient、无分页查询、事务里手动订阅，这些都不是“风格问题”，而是潜在生产事故入口。

## 4. 生产事故常见原因

| 现象 | 可能原因 | 排查方向 |
|---|---|---|
| 延迟突然升高 | 事件循环线程被阻塞 | 查 `block()`、同步 I/O、BlockHound |
| 内存上涨 | 大流量 `collectList()` 或背压失效 | 查堆、缓冲、响应体大小 |
| 下游被打爆 | `flatMap` 并发无限制或重试风暴 | 查并发参数、重试策略 |
| 连接池耗尽 | 超时太长、连接未释放、下游慢 | 查 pending acquire、active connections |
| 日志爆炸 | 流上逐条 INFO | 降采样、聚合日志 |
| traceId 丢失 | ThreadLocal 不适配异步链路 | 用 Reactor Context |

## 5. 最小最佳实践模板

```java
public Mono<UserPage> getUserPage(Long userId) {
    Mono<User> user = userClient.getUser(userId)
            .timeout(Duration.ofSeconds(2))
            .retryWhen(Retry.backoff(1, Duration.ofMillis(100))
                    .filter(this::retryable))
            .onErrorMap(ex -> new RemoteException("用户服务异常", ex));

    Mono<List<Order>> orders = orderClient.getRecentOrders(userId)
            .take(20)
            .collectList()
            .timeout(Duration.ofSeconds(2));

    return Mono.zip(user, orders)
            .map(tuple -> new UserPage(tuple.getT1(), tuple.getT2()))
            .doOnError(ex -> log.error("查询用户页失败, userId={}", userId, ex));
}
```

注意这里的 `collectList()` 有 `take(20)` 限制。如果没有上限，就不要收集成列表。

## 6. 从入门到大神复习路线

第一轮：跑通

1. 会创建 WebFlux 项目。
2. 会写 `Mono` 返回单对象。
3. 会写 `Flux` 返回列表。
4. 会用 `WebClient` 调接口。
5. 会写 `WebTestClient` 测试。

第二轮：写对

1. 熟练使用 `map`、`flatMap`、`zip`、`switchIfEmpty`。
2. 统一错误处理。
3. 所有远程调用有超时。
4. 不在 Controller/Service 中 `subscribe()`。
5. 不在事件循环线程上阻塞。

第三轮：上线

1. 能做连接池和并发上限配置。
2. 能压测并观察瓶颈。
3. 能接入 tracing 和 metrics。
4. 能排查阻塞、背压、内存、连接池问题。
5. 能给出是否使用 WebFlux 的架构判断。

## 7. 终极口诀

1. `Mono` 一个，`Flux` 多个。
2. `map` 改值，`flatMap` 接异步。
3. 不 `block`，不乱 `subscribe`。
4. 阻塞遗留系统进 `boundedElastic`。
5. 远程调用必须超时，重试必须克制。
6. 大流不要随手收集成 List。
7. WebFlux 是工程选择，不是简历装饰。

> [!abstract] 最后一遍复习
> WebFlux 的核心不是语法，而是资源模型：线程不乱阻塞、连接不乱占用、请求不无限堆积、错误不悄悄丢失、下游不被重试打爆。
