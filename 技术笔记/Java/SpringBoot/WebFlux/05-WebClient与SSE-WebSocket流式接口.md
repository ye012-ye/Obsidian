---
title: 05-WebClient 与 SSE WebSocket 流式接口
tags:
  - Java
  - WebFlux
  - WebClient
  - SSE
  - WebSocket
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 学会使用 WebClient 调用远程服务，处理状态码、超时、重试、连接池、SSE 流式响应和 WebSocket 长连接。
---

# 05-WebClient 与 SSE WebSocket 流式接口

> [!info] 本章抓什么
> WebClient 是 WebFlux 项目里最常用的外部 I/O 工具。重点学会状态码处理、超时、重试、连接池和流式响应，而不是只会写一个 `.retrieve().bodyToMono()`。

## 1. WebClient 是什么

`WebClient` 是 Spring 的响应式 HTTP 客户端。即使项目还是 Spring MVC，也经常引入 WebFlux 只为了使用 `WebClient`。

创建配置：

```java
@Configuration
public class HttpClientConfig {
    @Bean
    WebClient userWebClient(WebClient.Builder builder) {
        return builder
                .baseUrl("https://user-service.internal")
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .build();
    }
}
```

## 2. GET 调用

```java
@Component
public class UserClient {
    private final WebClient webClient;

    public UserClient(WebClient userWebClient) {
        this.webClient = userWebClient;
    }

    public Mono<UserDTO> getUser(Long id) {
        return webClient.get()
                .uri("/users/{id}", id)
                .retrieve()
                .bodyToMono(UserDTO.class);
    }
}
```

## 3. POST 调用

```java
public Mono<OrderDTO> createOrder(CreateOrderRequest request) {
    return webClient.post()
            .uri("/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .bodyValue(request)
            .retrieve()
            .bodyToMono(OrderDTO.class);
}
```

## 4. 处理状态码

```java
public Mono<UserDTO> getUser(Long id) {
    return webClient.get()
            .uri("/users/{id}", id)
            .retrieve()
            .onStatus(HttpStatusCode::is4xxClientError,
                    response -> response.bodyToMono(String.class)
                            .defaultIfEmpty("")
                            .flatMap(body -> Mono.error(new RemoteBadRequestException(body))))
            .onStatus(HttpStatusCode::is5xxServerError,
                    response -> Mono.error(new RemoteServiceException("用户服务异常")))
            .bodyToMono(UserDTO.class);
}
```

`retrieve()` 简洁，适合大多数场景。需要拿完整响应头、状态码时用 `exchangeToMono()`：

```java
return webClient.get()
        .uri("/users/{id}", id)
        .exchangeToMono(response -> {
            if (response.statusCode().is2xxSuccessful()) {
                return response.bodyToMono(UserDTO.class);
            }
            if (response.statusCode().value() == 404) {
                return Mono.empty();
            }
            return response.createException().flatMap(Mono::error);
        });
```

## 5. 超时、重试、降级

```java
public Mono<UserDTO> getUserWithPolicy(Long id) {
    return getUser(id)
            .timeout(Duration.ofSeconds(2))
            .retryWhen(Retry.backoff(2, Duration.ofMillis(200))
                    .filter(this::isRetryable))
            .onErrorResume(ex -> fallbackUser(id));
}

private boolean isRetryable(Throwable ex) {
    return ex instanceof TimeoutException || ex instanceof RemoteServiceException;
}
```

重试原则：

1. 只重试幂等请求，或业务能承受重复。
2. 必须有最大次数。
3. 最好带退避，不要固定间隔猛烈重试。
4. 重试失败后要降级或返回清晰错误。

> [!danger] 重试红线
> 没有超时的重试是事故放大器，没有最大次数的重试是下游压力制造机，非幂等请求乱重试可能造成重复扣款、重复下单、重复发消息。

## 6. 连接池与底层 Netty 配置

```java
@Bean
WebClient webClient() {
    ConnectionProvider provider = ConnectionProvider.builder("remote-pool")
            .maxConnections(200)
            .pendingAcquireTimeout(Duration.ofSeconds(3))
            .maxIdleTime(Duration.ofSeconds(30))
            .build();

    HttpClient httpClient = HttpClient.create(provider)
            .responseTimeout(Duration.ofSeconds(5));

    return WebClient.builder()
            .clientConnector(new ReactorClientHttpConnector(httpClient))
            .baseUrl("https://api.example.com")
            .build();
}
```

连接池不是越大越好。连接数要结合下游容量、实例数、超时时间和峰值并发评估。

> [!warning] 连接池提醒
> 连接池太小会排队，太大会把下游打穿。生产配置要结合压测、下游限额、实例数一起算，不能只在本服务里看吞吐。

## 7. 消费 SSE

```java
public Flux<String> streamAiAnswer(String prompt) {
    return webClient.post()
            .uri("/ai/chat")
            .contentType(MediaType.APPLICATION_JSON)
            .accept(MediaType.TEXT_EVENT_STREAM)
            .bodyValue(Map.of("prompt", prompt))
            .retrieve()
            .bodyToFlux(String.class);
}
```

如果服务端返回 `ServerSentEvent<T>`：

```java
ParameterizedTypeReference<ServerSentEvent<String>> type =
        new ParameterizedTypeReference<>() {};

return webClient.get()
        .uri("/events")
        .retrieve()
        .bodyToFlux(type)
        .map(ServerSentEvent::data);
```

## 8. WebSocket 简例

```java
@Configuration
public class WebSocketConfig {
    @Bean
    HandlerMapping webSocketMapping(ChatWebSocketHandler handler) {
        Map<String, WebSocketHandler> map = Map.of("/ws/chat", handler);
        SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
        mapping.setUrlMap(map);
        mapping.setOrder(10);
        return mapping;
    }

    @Bean
    WebSocketHandlerAdapter handlerAdapter() {
        return new WebSocketHandlerAdapter();
    }
}
```

Handler：

```java
@Component
public class ChatWebSocketHandler implements WebSocketHandler {
    @Override
    public Mono<Void> handle(WebSocketSession session) {
        Flux<WebSocketMessage> output = session.receive()
                .map(WebSocketMessage::getPayloadAsText)
                .map(text -> "echo: " + text)
                .map(session::textMessage);

        return session.send(output);
    }
}
```

## 9. WebClient 最佳实践

1. 复用 `WebClient`，不要每次请求都新建。
2. 给远程调用设置超时。
3. 对关键下游设置连接池上限。
4. 用 `onStatus` 处理非 2xx 状态。
5. 日志里记录 traceId、url、状态码、耗时，不要记录敏感数据。
6. 大响应体要流式处理，避免 `collectList()` 把内存打爆。
7. 下游不稳定时配合熔断、限流、隔离和降级。

> [!success] 最小生产模板
> 一个可靠的 WebClient 调用至少要有：基础 URL、连接池、响应超时、状态码映射、业务异常、有限重试、日志 traceId。少一个都可能让排障变难。
