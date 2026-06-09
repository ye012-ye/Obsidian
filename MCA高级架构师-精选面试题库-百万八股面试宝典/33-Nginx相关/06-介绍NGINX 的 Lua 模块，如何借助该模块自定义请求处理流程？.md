NGINX 的 Lua 模块（通常通过 OpenResty 提供）嵌入了 LuaJIT，使得开发者可以在 NGINX 内部运行 Lua 脚本，实现高度灵活的请求处理逻辑，无需编写 C 模块。

M

### 1. 核心优势

Lua 模块结合 NGINX 的异步事件模型，支持协程（coroutine）和非阻塞 I/O，可在性能几乎不受影响的情况下，实现复杂逻辑，例如动态路由、身份验证、请求/响应修改等。

S

### 2. 如何启用与引用

- 推荐使用 OpenResty，它自带 LuaJIT、ngx\_http\_lua\_module 和常用 `lua-resty-*` 库，安装更简单。
- 在 NGINX 配置中，通过以下方式在特定阶段执行 Lua 脚本：

```nginx
http {
  lua_package_path "/path/to/lua/scripts/?.lua;;";
  server {
    location /api {
      access_by_lua_file /path/to/check_auth.lua;
      content_by_lua_block {
        ngx.say("Hello from Lua!");
      }
    }
  }
}
```

`lua_package_path` 定义脚本搜索路径；`access_by_lua_file` 用于权限校验；`content_by_lua_block` 用于生成响应。

B

总结： NGINX 的 Lua 模块，特别是在 OpenResty 中，通过内嵌 LuaJIT 和常用库，支持在访问、内容生成等阶段插入逻辑，构建灵活高效的微型网关、认证层和 API 服务。凭借其异步 I/O 和高性能，非常适合替代传统后端实现轻量处理逻辑。

​
