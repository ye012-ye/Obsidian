NGINX 支持高并发的核心在于其事件驱动的异步架构以及精细的配置调优。以下从处理流程、配置项和优化建议三个方面进行说明：M

### 1. 并发请求处理机制

NGINX 基于 Master–Worker 架构：主进程负责管理配置和启动 Worker，Worker 进程绑定核心运行，执行事件循环。  
Worker 进程利用 `epoll`（Linux）或其他多路复用机制，监听连接的可读写事件并触发处理回调。整个过程中，无需为每个连接创建线程或阻塞等待，从而单个进程即可管理成千上万的连接，大大提升并发能力。S

### 2. 核心配置与优化要点

- **worker\_processes**：建议设置为 `auto` 或与 CPU 核心数一致，有时略超也可提升 IO 密集型场景性能。
- **worker\_connections**：每个 Worker 允许的最大连接数。性能上限约为 `worker_processes × worker_connections`，但要注意系统文件描述符的限制。
- **worker\_rlimit\_nofile**：提升单进程可打开的最大文件描述符，建议设置为 `worker_processes × worker_connections × 2`，避免因 FD 限制导致失败。
- **events 模块**：启用 `multi_accept on; use epoll;`，可提升接入新连接批处理效率。
- **Keep‑alive 设置**：启用持久连接可减少频繁的 TCP 握手成本，`keepalive_timeout`可视访问模式调整（如设为 15–65 秒）。
- **缓冲区调整**：如 `client_body_buffer_size`, `client_header_buffer_size`, `sendfile`, `tcp_nodelay` 等可根据静态/动态内容特性优化 IO 性能。
- **压缩与缓存**：启用 gzip 压缩（针对文本较大的文件）、静态文件设置较长过期时间，以及 proxy\_cache/fastcgi\_cache，可减少后端压力和网络带宽。B

### 示例配置片段

```nginx
worker_processes auto;
worker_rlimit_nofile 40000;

events {
  use epoll;
  multi_accept on;
  worker_connections 8000;
}

http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 15;
  client_body_buffer_size 10K;
  client_header_buffer_size 1K;

  gzip on;
  gzip_min_length 10240;
  gzip_types text/plain text/css application/javascript;

  location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 30d;
    access_log off;
  }
}
```
