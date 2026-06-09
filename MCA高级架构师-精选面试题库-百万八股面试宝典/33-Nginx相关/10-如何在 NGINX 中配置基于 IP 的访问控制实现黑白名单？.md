在 NGINX 中，通过 `ngx_http_access_module` 配合 `allow` 和 `deny` 指令，可以轻松实现 IP 的白名单与黑名单控制，从而保护关键资源免受未授权访问：M

首先，在指定的 `http`、`server` 或 `location` 块内配置访问规则：

```nginx
location /admin {
  deny  192.168.1.1;             # 拒绝单一 IP
  allow 192.168.1.0/24;          # 白名单网段
  allow 2001:db8::/32;           # 支持 IPv6 范围
  deny  all;                     # 拒绝所有其它请求
}
```

NGINX 按顺序匹配规则，一旦 `allow` 或 `deny` 命中，就立即生效。这种方式适用于规则清晰且变动不大的访问控制场景。

当规则数量较多或需动态更新时，推荐使用 `ngx_http_geo_module` 生成 IP 变量，再结合判断实现控制，例如：

```nginx
geo $blocked {
  default 1;
  203.0.113.0/24 0;
  198.51.100.42  0;
}

server {
  if ($blocked) { return 403; }
  # 其他配置...
}
```

这种方式使得 IP 黑白名单可以集中管理，配置更加整洁、高效。

配置完成后，通过 `nginx -t` 检查语法，使用 `nginx -s reload` 生效。建议按模块拆分 IP 列表并 `include` 引入，以便后续维护与更新。
