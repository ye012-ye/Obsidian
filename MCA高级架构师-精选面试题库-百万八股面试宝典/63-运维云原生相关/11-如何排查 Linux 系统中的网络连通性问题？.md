在 Linux 系统中，诊断网络故障时通常从基础连通性测试开始，逐步深入排查 DNS、路径、路由、套接字状态等方面。以下介绍关键命令及其用途。M

#### **ping**

`ping <目标 IP 或域名>` 用于检查本机与目标主机之间的 ICMP 连通性。可用 `ping -c 4 8.8.8.8` 跳过 DNS 测试，聚焦网络连通性与延迟。通过 RTT（往返时延）和丢包率判断连接质量。最常用的初步诊断工具。

#### **traceroute / tracepath**

`traceroute www.example.com` 或 `tracepath www.example.com` 用于跟踪数据包路径，显示经过的每个跳节点及每跳响应时延。适用于定位延迟或路由故障的具体跳数。`tracepath` 可在部分系统无需 root 权限运行。

#### **nslookup、dig、host**

- `nslookup example.com`：查询 DNS 解析结果，检测 DNS 服务器问题。
- `dig example.com`：获取多种 DNS 记录（如 A、CNAME、MX 等），便于深入诊断。
- `host domain.com`：简洁查询主机名或 IP 映射。  
  这些工具能帮助确认是否由 DNS 问题导致访问失败。

#### **ip / ifconfig / route / arp**

- `ip addr show` 或传统 `ifconfig` 查看网络接口状态、IP 和网关信息。
- `ip route` 或 `route -n` 查看当前系统的路由表，确认默认路由是否设置正确。
- `ip neighbor` 或 `arp -a` 显示 ARP 缓存，用于检查本地 IP–MAC 映射是否异常。

#### **netstat / ss**

- `netstat -tulnp` 或更现代的 `ss -tulnp` 用于查看系统当前的监听端口和连接状态，并可关联进程 PID，排查端口冲突或服务未启动。
- `netstat -r` 查看路由表，配合 `ip route` 使用方便。  
  `ss` 是 `netstat` 的推荐替代工具，性能更优。

#### **tcpdump、mtr、iftop***(可选补充)*

- `tcpdump` 捕获与分析网络数据包，适用于复杂故障情况下精确诊断。
- `mtr` 结合 `ping` 和 `traceroute` 功能实时跟踪网络路径与丢包状况。
- `iftop` 显示实时带宽使用情况，帮助识别网络流量热点。

S

### 工具命令：

|  |  |
| --- | --- |
| 命令 | 主要用途 |
| `ping` | 测试目标连通性、延迟与丢包率 |
| `traceroute` / `tracepath` | 跟踪数据包路径，定位故障跳点 |
| `nslookup` / `dig` / `host` | 验证 DNS 解析结果与记录 |
| `ip addr` / `ifconfig` | 查看接口状态与 IP 地址 |
| `ip route` / `route` | 检查路由表，确认默认网关及路由设置 |
| `arp` / `ip neighbor` | 检查 IP-MAC 映射，诊断 ARP 问题 |
| `netstat` / `ss` | 查看网络连接与监听端口状态 |
| `tcpdump`, `mtr`, `iftop` | 捕包分析；实时追踪路径或带宽使用 |

总结： 进行网络连通性排查时的基本流程为：首先用 `ping` 检查目标是否可达，再用 `traceroute` 定位路径问题；若疑似为 DNS 问题，可用 `nslookup` 或 `dig` 分析；确认接口与路由配置时使用 `ip`、`ifconfig` 和 `route`；最后通过 `ss` 或 `netstat` 查看服务端口与连接状态。多个工具组合使用可以迅速锁定网络层的问题根源。
