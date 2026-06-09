HTTP 连接的生命周期分为两类：**短连接**（Short-lived）和**长连接**（Persistent / Keep-alive）。

### HTTP 长连接与短连接 ​

**长连接**（即 HTTP Keep-alive）：  
客户端与服务器建立 TCP 连接后，可以通过同一个连接发送多个 HTTP 请求/响应，连接持续开启直到超时或达到请求次数限制。这样可以避免反复握手和断开，显著减小延迟和资源开销。

**短连接**：  
每个请求都建立一个新 TCP 连接，请求结束后立即关闭。虽然实现简单，但会频繁进行三次握手和四次挥手，增加延迟和资源消耗。

### NGINX 中的连接管理

#### 1. 客户端连接（HTTP）

- 使用 `keepalive_timeout` 控制空闲连接的关闭时间，例如：

```nginx
keepalive_timeout 75s;
```

表示在响应完成后，连接若闲置 75 秒则关闭。

- `keepalive_requests` 指定单连接允许的最大请求数，超过则强制关闭，例如：

```nginx
keepalive_requests 1000;
```

用于释放连接相关资源 。

- `keepalive_time`（NGINX ≥1.19.10）设置连接的最大存在周期，即使不断请求，也会在指定时间后关闭。

#### 2. 与上游服务器（反向代理或负载均衡）

- 在 `upstream` 模块中启用 keepalive：

```nginx
upstream backend {
  server backend1:80;
  keepalive 8;
}
```

并在代理时使用 HTTP/1.1 协议，并去除 `Connection: close` 头，以重用连接：

```nginx
proxy_http_version 1.1;
proxy_set_header Connection "";
```

这样减少与后端握手开销，提高性能。
