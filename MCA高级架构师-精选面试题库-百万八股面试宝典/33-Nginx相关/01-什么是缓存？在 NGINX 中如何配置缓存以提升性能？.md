缓存是为了加速访问而设计的一种机制，它将从后端获取的响应副本临时存储在靠近客户端的位置（如内存或磁盘），免去重复请求后端的开销，从而减少响应时间和后端资源消耗，是提升系统吞吐和用户体验的有效手段。

​

### 1. 配置反向代理缓存（proxy\_cache）

在 `http {}` 块配置缓存路径和元数据区，例如：

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m max_size=10g inactive=60m use_temp_path=off;
```

- `levels`：缓存目录分层，避免单目录文件过多；
- `keys_zone`：共享内存存储缓存键与状态，10 MB 可容纳约 80 k 条键数据；
- `max_size`：磁盘缓存上限；
- `inactive`：内容闲置多长时间清除缓存。

然后在 `server/location` 中启用：

```nginx
proxy_cache mycache;
proxy_cache_key $scheme$host$request_uri;
proxy_cache_valid 200 302 10m;
proxy_cache_valid 404 1m;
proxy_cache_use_stale error timeout updating http_500 http_502 http_503;
proxy_pass http://backend;
```

- `proxy_cache_key` 控制缓存唯一性；
- `proxy_cache_valid` 定义针对 HTTP 状态码的缓存时长；
- `proxy_cache_use_stale` 后端错误或超时时返回旧缓存 。

### ​2. 配置 FastCGI 缓存（动态内容缓存）

适用于 PHP-FPM 等后端：

```nginx
fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2 keys_zone=fcgicache:10m max_size=5g inactive=30m;
server {
  location ~ \.php$ {
    fastcgi_pass unix:/var/run/php-fpm.sock;
    fastcgi_cache fcgicache;
    fastcgi_cache_key $scheme$host$request_uri;
    fastcgi_cache_valid 200 302 5m;
    fastcgi_disable_header X-Accel-Expires;
    fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;
  }
}
```

FastCGI 缓存将 PHP 渲染结果存储为静态 HTML，后续访问可直接命中缓存，显著减轻 PHP-FPM 和数据库负载。

### ​3. 配置浏览器缓存（静态资源）

在静态资源 `location` 块中添加：

```nginx
location ~* \.(css|js|png|jpg|ico|svg)$ {
  expires 30d;
  add_header Cache-Control "public";
}
```

该配置通过 HTTP 头指示浏览器缓存资源，避免重复下载，加快页面加载速度。

### 4. 高级优化策略

- 使用 `proxy_cache_min_uses` 避免冷缓存急速膨胀，仅缓存被多次请求的资源；
- 使用 `proxy_cache_revalidate` 启用条件请求机制；
- 使用 `proxy_cache_bypass` 和 `proxy_no_cache` 控制特定请求不缓存，如带 Cookie 内容；
- 使用 `X-Accel-Expires` 覆盖缓存设置；
- 启用缓存 purge 功能，用于动态刷新或清理失效条目。

​

总结： 通过配置 `proxy_cache_path + proxy_cache` 的反向代理缓存，与 `fastcgi_cache` 的动态页面缓存，以及为静态资源设置浏览器缓存头，再结合缓存策略（清除、条件缓存、命中控制等），NGINX 可以大幅减少后端负载、提升响应速度、并优化带宽使用，是构建高性能 Web 服务的重要措施。
