**HTTP缓冲区溢出（Buffer Overflow）** 是当程序向预分配的内存缓冲区写入超出其容量的数据时发生的漏洞，攻击者可能利用它覆盖关键内存区域，导致程序崩溃、异常行为，甚至远程执行恶意代码 。

M

### NGINX 防止缓冲区溢出的策略

**1. 配置缓冲区大小限制**  
通过指令 `client_header_buffer_size`、`large_client_header_buffers`、`client_body_buffer_size`、`client_max_body_size`，在解析请求头和请求体时强制设置合理的内存上限。例如将头部缓冲区控制在1KB，最大请求体限制为1MB，可有效规避因异常巨大输入触发内存溢出的风险。S

**2. 及时升级和修复漏洞**  
历史上如版本1.3.9–1.4.0存在的栈溢出漏洞（CVE-2013-2028）、以及最新 HTTP/3 中的缓冲区覆盖（CVE‑2024‑32760）等，NGINX 官方均已发布补丁解决。务必定期关注安全公告并升级至安全版本。

**3. 编译与系统级保护**  
NGINX 可编译时启用栈保护（如 GCC 的 `-fstack-protector-strong`），并运行在具备 ASLR 与 NX/DEP 的操作系统上，用来防止堆/栈上的数据被执行或被未知覆盖。

**4. WAF 与请求过滤**  
借助 ModSecurity、NAXSI 等 Web 应用防火墙，可针对异常请求头、大范围 header 或 chunked 请求等模式实时拦截，并返回错误或断开连接，进一步防范潜在攻击。

B

​
