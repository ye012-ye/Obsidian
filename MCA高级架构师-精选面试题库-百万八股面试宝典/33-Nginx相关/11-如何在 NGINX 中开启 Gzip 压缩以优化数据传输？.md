要在 NGINX 中启用 Gzip 压缩，减少传输数据量、提升加载速度，可按如下流程配置：

首先，在 `http { … }` 块中启用 Gzip，并设置压缩参数：

```nginx
gzip on;
gzip_disable "MSIE [1-6]\.";            # 避免旧浏览器问题
gzip_vary on;                           # 添加 Vary 头，支持共享缓存
gzip_proxied any;                       # 压缩所有代理请求，包括通过代理转发的响应
gzip_http_version 1.1;                 # 仅对 HTTP/1.1+ 请求启用压缩
gzip_min_length 256;                   # 对响应大小 ≥ 256 字节才压缩 :contentReference[oaicite:4]{index=4}
```

接着，指定可压缩的 MIME 类型：

```nginx
gzip_types
text/plain
text/css
application/json
application/javascript
application/xml
text/xml
application/rss+xml
application/atom+xml
image/svg+xml
font/opentype
image/x-icon;
```

默认情况下，NGINX 只压缩 `text/html`，需要通过 `gzip_types` 增量支持其他类型。

然后，设置压缩级别、缓冲区等参数：

```nginx
gzip_comp_level 5;                      # 推荐 5~6，压缩效果与 CPU 平衡 optimal :contentReference[oaicite:8]{index=8}
gzip_buffers 16 8k;                    # 设置压缩缓冲区
```

可选高级配置包括：

- `gzip_static on;`：直接提供预压缩的 `.gz` 文件，避免运行时计算；
- `gunzip on;`：对客户端不支持 Gzip 的响应自动解压；
- 关注 SSL 时的安全（如 BREACH 漏洞风险）。

完成配置后，重启或热加载 NGINX，并通过以下命令验证压缩效果：

```bash
curl -H "Accept-Encoding: gzip" -I http://your.site/
```

若返回 `Content-Encoding: gzip`，表明 Gzip 正常工作。
