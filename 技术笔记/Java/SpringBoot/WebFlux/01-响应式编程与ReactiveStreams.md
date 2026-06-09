---
title: 01-响应式编程与 Reactive Streams
tags:
  - Java
  - WebFlux
  - ReactiveStreams
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 理解 WebFlux 背后的响应式思想、非阻塞 I/O、背压、Publisher/Subscriber/Subscription/Processor 四大接口，以及它和传统 MVC 的本质区别。
---

# 01-响应式编程与 Reactive Streams

> [!info] 本章抓什么
> 这一章先解决“为什么需要 WebFlux”。你不需要一开始就背操作符，先把阻塞、非阻塞、异步、背压这几个词分清楚，后面看 `Mono`、`Flux` 会轻松很多。

## 1. 为什么会有 WebFlux

传统 Spring MVC 很好用，但它的经典执行模型是：

1. 客户端发起请求。
2. Web 容器分配一个线程处理请求。
3. Controller 调数据库、Redis、远程 HTTP。
4. 如果 I/O 没返回，这个线程就阻塞等待。
5. I/O 返回后继续执行，写出响应。

当并发不高、业务简单时，这个模型非常清晰。但如果系统大量时间都在等网络 I/O，比如订单页同时调用用户、库存、优惠券、物流、推荐等多个服务，线程会大量卡在等待上。WebFlux 的目标不是让单次业务更快，而是减少等待 I/O 时被占住的线程数量，让系统用更少的线程承载更多并发连接。

## 2. 阻塞、非阻塞、同步、异步

这四个词经常混在一起，先拆开：

| 概念 | 关注点 | 例子 |
|---|---|---|
| 阻塞 | 调用方是否停住等待结果 | `jdbcTemplate.query()` 查询未返回前线程卡住 |
| 非阻塞 | 调用方发起操作后可以继续做别的 | Netty 发起网络读写后由事件回调通知 |
| 同步 | 调用结果是否在当前调用链直接返回 | 方法调用返回结果或抛异常 |
| 异步 | 结果未来再通过回调、Future、Publisher 通知 | `CompletableFuture`、`Mono`、`Flux` |

WebFlux 追求的是异步 + 非阻塞。它把请求处理变成“声明一条流水线”，真正的数据到来时再由运行时推进。

## 3. Reactive Streams 四大角色

Reactive Streams 是一套标准接口，核心解决“异步数据流 + 背压”。

| 接口               | 角色    | 你可以怎么理解          |
| ---------------- | ----- | ---------------- |
| `Publisher<T>`   | 数据发布者 | 上游，能发出 0 到 N 个元素 |
| `Subscriber<T>`  | 数据订阅者 | 下游，接收元素、错误、完成信号  |
| `Subscription`   | 订阅关系  | 下游通过它向上游请求多少数据   |
| `Processor<T,R>` | 中间处理器 | 既是订阅者又是发布者       |

信号顺序大致是：

```text
onSubscribe -> request(n) -> onNext... -> onComplete
                                 \-----> onError
```

重点是 `request(n)`。下游不是被动被塞满，而是可以告诉上游“我现在只能处理 n 个”。这就是背压。

## 4. 什么是背压

背压就是“消费者处理不过来时，能把压力反向传给生产者”。

> [!example] 生活化理解
> 没有背压就像窗口还没处理完，后面的人继续无限往窗口塞材料；有背压就是窗口说“我现在只能接 10 份”，上游按处理能力投递，队列不会无脑膨胀。

没有背压的情况：

1. 上游每秒生产 10000 条消息。
2. 下游每秒只能处理 1000 条。
3. 中间队列越来越大。
4. 内存上涨、GC 变频繁，最后 OOM。

有背压的情况：

1. 下游通过 `request(n)` 声明处理能力。
2. 上游按需发送。
3. 中间缓冲可控。
4. 系统退化更平稳。

在 WebFlux 中，HTTP 请求体、响应体、SSE 事件、数据库结果流、远程服务调用结果，都可以被统一成响应式流来组合。

## 5. WebFlux 与 MVC 的本质区别

| 对比点 | Spring MVC | Spring WebFlux |
|---|---|---|
| 底层模型 | Servlet 阻塞模型为主 | Reactive Streams 非阻塞模型 |
| 默认服务器 | Tomcat | Reactor Netty |
| 编程返回值 | 对象、集合、`ResponseEntity` | `Mono<T>`、`Flux<T>` |
| 并发承载 | 多线程，一请求一线程倾向 | 少量事件循环线程处理大量连接 |
| 数据访问 | JDBC/JPA 常见 | R2DBC、Reactive MongoDB 等 |
| 学习成本 | 低 | 高 |
| 排障难度 | 调用栈直观 | 异步链路需要专门工具和经验 |

## 6. 最重要的思维转换

MVC 写法像“马上拿到值”：

```java
User user = userRepository.findById(id);
Order order = orderRepository.findLatestByUserId(user.getId());
return new UserOrderView(user, order);
```

WebFlux 写法像“描述值未来到达后怎么处理”：

```java
return userRepository.findById(id)
        .flatMap(user -> orderRepository.findLatestByUserId(user.id())
                .map(order -> new UserOrderView(user, order)));
```

第一段代码里，`user` 是已经拿到的对象。第二段代码里，`Mono<User>` 不是对象本身，而是一个未来可能发出 `User` 的异步容器。

## 7. WebFlux 不是万能药

下面这些误区要早点避开：

1. `Mono` 和 `Flux` 不是集合，它们是异步数据流。
2. WebFlux 不会让数据库查询本身变快。
3. 如果底层全是 JDBC/JPA 阻塞调用，WebFlux 的收益会被抵消。
4. 在事件循环线程里 `Thread.sleep()`、`block()`、同步 HTTP 调用，会严重拖垮系统。
5. 响应式链路里异常不会像同步代码那样总能被 `try-catch` 捕获，要用响应式错误操作符。

> [!danger] 第一条红线
> WebFlux 最怕“看起来是响应式，实际到处阻塞”。一旦事件循环线程被 `block()`、`Thread.sleep()`、JDBC、同步 HTTP 调用卡住，吞吐和延迟都会明显恶化。

## 8. 学到这一章你要能回答

1. WebFlux 解决的主要问题是什么？
2. Reactive Streams 的四个接口分别是什么？
3. 背压解决什么问题？
4. 为什么 WebFlux 里不建议随便 `block()`？
5. 什么场景继续用 Spring MVC 更合适？
