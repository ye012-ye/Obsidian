---
title: 02-Reactor Mono Flux 核心用法
tags:
  - Java
  - WebFlux
  - Reactor
  - Mono
  - Flux
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 系统掌握 Reactor 的 Mono、Flux、创建操作符、转换操作符、组合操作符、错误处理、调度器、冷热流和常见反模式。
---

# 02-Reactor Mono Flux 核心用法

> [!info] 本章抓什么
> Reactor 是 WebFlux 的发动机。本章重点不是把所有操作符背完，而是先掌握创建、转换、组合、错误处理、线程切换这五类高频能力。

## 1. Mono 和 Flux 是什么

`Mono<T>` 表示 0 或 1 个异步结果：

```java
Mono<User> user = userRepository.findById(1L);
Mono<Void> deleted = userRepository.deleteById(1L);
Mono.empty(); // 没有值，但正常完成
Mono.error(new RuntimeException("failed")); // 没有值，失败完成
```

`Flux<T>` 表示 0 到 N 个异步结果：

```java
Flux<User> users = userRepository.findAll();
Flux<Integer> numbers = Flux.just(1, 2, 3, 4);
Flux<Long> ticks = Flux.interval(Duration.ofSeconds(1));
```

记住：`Mono<User>` 不是 `User`，`Flux<User>` 也不是 `List<User>`。它们是数据未来到达时的处理计划。

## 2. 什么都不会发生，直到订阅

Reactor 链路默认是惰性的。只声明流水线不会执行：

```java
Mono<String> pipeline = Mono.just("java")
        .map(String::toUpperCase);
```

只有订阅后才开始：

```java
pipeline.subscribe(System.out::println);
```

在 WebFlux 里通常不需要你手动 `subscribe()`。Controller 返回 `Mono` 或 `Flux` 后，框架会替你订阅并把结果写入 HTTP 响应。

## 3. 常用创建方式

```java
Mono.just("ok");
Mono.empty();
Mono.error(new IllegalArgumentException("bad request"));
Mono.fromCallable(() -> blockingQuery());

Flux.just("a", "b", "c");
Flux.fromIterable(List.of("a", "b", "c"));
Flux.range(1, 10);
Flux.interval(Duration.ofSeconds(1));
```

如果包装阻塞调用，要配合调度器隔离：

```java
Mono.fromCallable(() -> legacyClient.query())
        .subscribeOn(Schedulers.boundedElastic());
```

## 4. 转换操作符

| 操作符              | 用途                    | 例子                    |
| ---------------- | --------------------- | --------------------- |
| `map`            | 同步一对一转换               | `User -> UserVO`      |
| `flatMap`        | 异步一对一转换               | `user -> Mono<Order>` |
| `flatMapMany`    | `Mono<T>` 转 `Flux<R>` | `user -> Flux<Order>` |
| `filter`         | 过滤元素                  | 只保留启用用户               |
| `switchIfEmpty`  | 空结果时切换                | 用户不存在时返回错误            |
| `defaultIfEmpty` | 空结果时给默认值              | 空昵称改成匿名               |

示例：

```java
public Mono<UserVO> findUserVO(Long id) {
    return userRepository.findById(id)
            .switchIfEmpty(Mono.error(new NotFoundException("用户不存在")))
            .map(user -> new UserVO(user.id(), user.name()));
}
```

`map` 里不能返回 `Mono`，否则会变成 `Mono<Mono<T>>`。涉及异步调用时用 `flatMap`。

> [!success] 记忆口诀
> `map` 改普通值，`flatMap` 接异步值。看到 Lambda 里返回 `Mono` 或 `Flux`，大概率就该用 `flatMap`。

## 5. 组合操作符

并行聚合两个无依赖结果：

```java
public Mono<UserPage> getUserPage(Long userId) {
    Mono<User> userMono = userRepository.findById(userId);
    Mono<Account> accountMono = accountClient.getAccount(userId);

    return Mono.zip(userMono, accountMono)
            .map(tuple -> new UserPage(tuple.getT1(), tuple.getT2()));
}
```

按顺序处理每个元素：

```java
return Flux.fromIterable(orderIds)
        .concatMap(orderService::payOne);
```

限制并发处理：

```java
return Flux.fromIterable(ids)
        .flatMap(remoteClient::fetchDetail, 8);
```

这里的 `8` 表示最多同时处理 8 个异步请求，生产上非常重要。

## 6. 错误处理

响应式链路里错误也是一种信号：

```java
return userRepository.findById(id)
        .timeout(Duration.ofSeconds(2))
        .onErrorResume(TimeoutException.class,
                ex -> Mono.error(new BizException("查询用户超时")))
        .onErrorMap(DataAccessException.class,
                ex -> new BizException("数据库访问失败", ex));
```

常用错误操作符：

| 操作符 | 用途 |
|---|---|
| `onErrorReturn` | 出错时返回固定值 |
| `onErrorResume` | 出错时切换到备用流 |
| `onErrorMap` | 转换异常类型 |
| `doOnError` | 记录日志，不吞异常 |
| `retryWhen` | 按策略重试 |
| `timeout` | 超时失败 |

不要用 `try-catch` 包住响应式链路期待捕获所有异常。链路内部异步阶段的异常要用操作符处理。

## 7. publishOn 和 subscribeOn

Reactor 官方文档强调，`Flux` 或 `Mono` 本身不意味着一定运行在专用线程上。执行位置由订阅线程和 `Scheduler` 决定。

> [!warning] 线程提醒
> `Scheduler` 不是越多越好。CPU 计算放 `parallel`，无法避免的阻塞 I/O 放 `boundedElastic`，不要把所有问题都甩给新线程池。

`subscribeOn` 影响上游订阅发生在哪个线程，通常放哪都能影响源头：

```java
Mono.fromCallable(this::blockingCall)
        .subscribeOn(Schedulers.boundedElastic())
        .map(this::toVO);
```

`publishOn` 影响它后面的操作在哪个线程执行：

```java
return loadUser()
        .publishOn(Schedulers.parallel())
        .map(this::cpuLightTransform)
        .publishOn(Schedulers.boundedElastic())
        .flatMap(this::callBlockingLegacySystem);
```

常用调度器：

| 调度器 | 适合场景 |
|---|---|
| `Schedulers.parallel()` | CPU 计算，线程数接近 CPU 核数 |
| `Schedulers.boundedElastic()` | 无法避免的阻塞 I/O |
| `Schedulers.single()` | 单线程串行任务 |
| `Schedulers.immediate()` | 当前线程 |

## 8. 冷流与热流

冷流：每个订阅者都会重新触发数据生产。

```java
Flux<Integer> cold = Flux.range(1, 3);
```

热流：数据独立于订阅者持续产生，后订阅的人可能错过之前的数据。SSE、WebSocket、消息订阅常见热流特征。

```java
Sinks.Many<String> sink = Sinks.many().multicast().onBackpressureBuffer();
Flux<String> hotFlux = sink.asFlux();
```

## 9. 最常见反模式

```java
// 反模式 1：在 Controller 中 block
User user = userRepository.findById(id).block();

// 反模式 2：map 里返回 Mono
Mono<Mono<Order>> wrong = userMono.map(user -> orderRepository.findByUserId(user.id()));

// 反模式 3：忘记限制 flatMap 并发
Flux.fromIterable(ids).flatMap(remoteClient::fetch);

// 反模式 4：doOnError 以为能兜底
mono.doOnError(ex -> log.error("failed", ex));
```

更合理的写法：

```java
return userRepository.findById(id)
        .flatMap(user -> orderRepository.findByUserId(user.id()))
        .onErrorResume(ex -> fallbackOrder())
        .timeout(Duration.ofSeconds(3));
```

> [!danger] 面试和代码审查重点
> 看到 `block()`、手动 `subscribe()`、无限制 `flatMap()`、大结果集 `collectList()`，先停下来问：这会不会阻塞事件循环、打爆下游、吃光内存，或者让请求生命周期失控？
