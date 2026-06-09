**1. DDoS 攻击定义**  
DDoS（分布式拒绝服务）攻击是一种通过大量分散源（如僵尸网络）发起流量或请求洪流的攻击手法，目的是耗尽目标服务器或网络资源，使合法用户无法访问服务。

M

**2. NGINX 限制并发连接与请求速率**

- 使用 `limit_conn` 限制每个 IP 的最大并发连接数。例如：

```nginx
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
server {
  limit_conn conn_limit 20;
}
```

这可以缓解 SYN flood 和大量连接攻击。

- 使用 `limit_req` 控制请求速率：

```nginx
limit_req_zone $binary_remote_addr zone=req_limit:10m rate=5r/s;
server {
  location / {
    limit_req zone=req_limit burst=10 nodelay;
  }
}
```

有效防止 HTTP 洪水攻击和应用层扫描。

**3. 超时与缓冲控制**

- 合理配置连接和响应超时（如 `proxy_read_timeout`、`client_body_timeout`），能及时释放挂起连接资源，防止攻击者占满连接池。
- 启用缓存和缓冲，将静态内容直接由 NGINX 提供，减少后端压力。

**4. IP 黑白名单与地理封锁**

- 使用 `allow` 和 `deny` 指令快速封锁已知恶意 IP，或者白名单关键 IP。
- 可用 `ngx_http_geo_module` 根据地理位置动态封锁大量来源地。

**5. 集成 WAF 或第三方策略**

- 使用 NGINX Plus 的 App Protect DoS 模块，提供行为层面检测与封锁机制。
- 可结合 CDN 或专业 DDoS 防护服务，对抗大规模网络层攻击。

**6. 可视化监控与弹性扩展**

- NGINX Plus 支持流量监控与 API 性能监控，帮助识别异常峰值。
- 在容器化或云端环境中部署多个 NGINX 实例，实现自动扩展，协同抵御高流量攻击。

​

总结： NGINX 可以通过限制连接数 (`limit_conn`)、请求速率 (`limit_req`)、超时设置、缓存机制和 IP 封锁构建第一道防线。进阶场景下，集成 WAF 模块（如 App Protect DoS）、CDN 及云防护服务，并配合监控和自动扩容，能够显著提升对抗 DDoS 攻击的能力。
