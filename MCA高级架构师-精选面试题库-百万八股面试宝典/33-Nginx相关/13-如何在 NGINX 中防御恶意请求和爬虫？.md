在 NGINX 中防御恶意请求和爬虫（Bots）需要从多方面协同策略实现，以下为主要策略与配置模块：

M

### 1. IP / 连接限制

通过 `ngx_http_limit_req_module` 可以针对每个 IP 设置请求速率限流：

```nginx
limit_req_zone $binary_remote_addr zone=rl:10m rate=10r/s;

server {
  location / {
    limit_req zone=rl burst=20 nodelay;
  }
}
```

此策略有效阻止短时间内大量请求（DDoS 和爬虫）。

若想限制并发连接，可配合 `ngx_http_limit_conn_module` 控制同一 IP 的连接数，增强保护。

### 2. User-Agent 黑名单

可使用 `map` 或 `if` 结合 `$http_user_agent` 设置黑名单，直接返回 403 阻挡已知爬虫：

```nginx
if ($http_user_agent ~* "(?:wget|curl|BadBot)") {
  return 403;
}
```

该方式简洁有效，但需定期更新爬虫列表。

S

### 3. 地理位置 / IP 地区控制

通过 `ngx_http_geo_module` 定义指定 IP 或国家的访问权限：

```nginx
geo $blocked {
  default 0;
  192.0.2.0/24 1;
}
server {
  if ($blocked) { return 444; }
}
```

适用于封锁来自可疑地区的大规模请求。

### 4. 第三方模块／WAF

- `NGINX App Protect` 提供高级 WAF 功能，能识别复杂恶意模式并拦截。
- DataDome 等实时 AI Bot 检测解决方案，适合高强度防护场景。

### 5. Referrer／Anti-hotlink

使用 `ngx_http_referer_module`，可仅允许指定来源访问特定资源，防止盗链和图片爬取。

B

### 6. 强化 HTTP 头与响应策略

添加安全头（如 `X-Robots-Tag: noai`）帮助控制搜索引擎/AI 爬虫访问策略。
