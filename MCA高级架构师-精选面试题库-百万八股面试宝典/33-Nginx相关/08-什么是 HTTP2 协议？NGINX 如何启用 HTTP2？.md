HTTP/2 是对 HTTP/1.1 的重大改进，它引入二进制帧、流多路复用、头部压缩（HPACK）和服务器推送等新特性，旨在降低延迟、提高资源传输效率并优化用户体验。

M

**1. 核心优势**

- **多路复用**：单一 TCP 连接中并行处理多个请求/响应，根治 HTTP/1.1 中的队头阻塞问题。
- **头部压缩**：HPACK 减少重复头部的传输量，显著降低数据开销。
- **服务器推送**（可选）：NGINX 支持主动推送资源，但需谨慎使用，否则可能浪费带宽。

S

**2. NGINX 如何启用 HTTP/2**

- 确保使用支持 HTTP/2 的版本（NGINX ≥ 1.9.5，源自 `ngx_http_v2_module`），并通过 `--with-http_v2_module` 编译启用。
- 配置 HTTPS 并启用 ALPN 支持（OpenSSL ≥ 1.0.2 提供必要功能）。
- 在 `listen` 指令中添加 `http2`：

```nginx
server {
  listen 443 ssl http2;
  ssl_certificate     /path/to/cert.pem;
  ssl_certificate_key /path/to/key.pem;
  # 可选 server_push_preload on;
}
```
