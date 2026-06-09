WebSocket 是一种为了实时通信而设计的协议，允许客户端和服务器在一个持久的 TCP 连接中进行**全双工（双向）交换数据**，避免了传统 HTTP 的轮询开销。连接通过标准 HTTP Upgrade 请求升级建立，一旦握手完成，服务器返回 `101 Switching Protocols` 响应，之后切入二进制帧形式数据交互。

### NGINX 中支持 WebSocket 的配置

从 **NGINX 1.3.13** 开始，支持 WebSocket 协议代理。配置时，关键在于保留并转发 Upgrade 请求头，具体步骤如下：

```nginx
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

server {
  listen 80;
  server_name example.com;

  location /ws {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

- `proxy_http_version 1.1;`：确保使用 HTTP/1.1 支持 Upgrade。
- `proxy_set_header Upgrade $http_upgrade;` 与 `Connection`：确保请求升级头被完整转发。
- `map` 指令根据 `$http_upgrade` 变量动态设置 Connection 字段，避免不必要数据丢失。

### ​HTTPS + WSS 安全部署

当使用 `wss://`（安全 WebSocket）时，请在 `listen 443 ssl http2;` 上配置 SSL 证书：

```nginx
server {
  listen 443 ssl;
  ssl_certificate     /path/to/cert.pem;
  ssl_certificate_key /path/to/key.pem;

  location /ws {
    # 同上配置信息...
  }
}
```

这样保证客户端与 NGINX 之间通过 TLS 加密通信，后台可与 HTTP 或 WSS 后端通信。
