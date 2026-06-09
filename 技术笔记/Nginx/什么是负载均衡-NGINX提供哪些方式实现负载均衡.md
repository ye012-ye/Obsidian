---
title: 什么是负载均衡？NGINX 提供哪些方式实现负载均衡？
source: https://mashibingmca.yuque.com/org-wiki-mashibingmca-ae2zgb/mca/mqzdogvog5as37g0
tags:
  - nginx
  - 负载均衡
  - 中间件
created: 2026-05-26
---

# 什么是负载均衡？NGINX 提供哪些方式实现负载均衡？

## 1. 负载均衡定义

负载均衡是一种将客户端请求智能分配到多台后端服务器的技术，旨在提高整体性能、增强可用性并防止单点过载。它通过横向扩展资源，确保系统在高负载情况下依然稳定响应。

## 2. NGINX 的负载均衡能力

NGINX 内置反向代理模块，支持 HTTP、HTTPS、TCP/UDP 场景下的负载均衡，能够均衡分发请求并自动跳过故障服务器。

## 3. 核心调度算法

- **轮询（Round Robin，默认）**
  简单依次分发请求到每台服务器，适合资源均等的场景。

- **带权轮询（Weighted Round Robin）**
  按配置权重比例分发请求，更强能力的服务器可承担更多请求。

- **最少连接（Least Connections）**
  请求发往当前连接数最少的服务器，更适合请求处理时间不均的场景。

- **IP 哈希（IP Hash）**
  客户端 IP 被哈希映射到固定后端，实现基础粘性，会话一致性。

## 4. 配置示例

```nginx
http {
  upstream backend {
    least_conn;
    server 10.0.0.1 weight=3 max_fails=2 fail_timeout=30s;
    server 10.0.0.2 weight=2;
    server 10.0.0.3;
  }

  server {
    listen 80;
    location / {
      proxy_pass http://backend;
    }
  }
}
```

该配置使用最少连接策略，并允许运行时自动剔除故障节点。

## 5. 健康检查与连接复用

NGINX 支持被动健康检测（如 `max_fails` 与 `fail_timeout`），失败节点短期自动隔离，每次请求重试尝试恢复。同时，支持前端和后端的长连接（`keepalive`）复用，减少 TCP 握手，提高效率。

## 6. 粘性会话与扩展模块

- 通过 `ip_hash` 实现客户端黏性分发，确保同一用户请求发往同一服务器。
- 对于更复杂的会话粘性需求，可以使用第三方 sticky 模块或 NGINX Plus 支持的高级算法。

## 总结

NGINX 实现负载均衡是通过定义 `upstream` 服务器组并选择轮询、权重轮询、最少连接、IP 哈希等算法，实现请求分发、故障检测和连接复用功能，提升系统的性能、可用性和伸缩性。
