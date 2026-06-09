VLAN（Virtual Local Area Network）是一种基于二层交换机逻辑划分广播域的技术，它能将物理网络隔离为多个独立的逻辑网络，从而控制广播、提升安全性与网络管理的灵活性。VLAN 在实际场景中用于根据部门、功能或安全策略，将不同设备分隔到不同子网中，即使它们物理位于同一交换机上也无法互相通信，除非通过三层设备（如路由器或三层交换机）实现互联。此隔离方式既简化了网络拓扑，也有助于减少广播风暴并提高性能。

M

### VLAN 的主要作用

通过将设备逻辑分组，VLAN 可以控制广播域大小、减少无效流量、提高内网安全性，并使网络配置更加模块化。不同 VLAN 之间默认互不通信，如果需要通信，则必须配置路由功能，这样在总体上提高了管理的精细度和数据访问的控制能力。同时，VLAN 还支持在不更改物理布线的前提下灵活调整网络布局，对于多租户数据中心和大型企业网络最为重要。

S

### 配置方式（Cisco Switch 为例）

1. **创建 VLAN**  
   进入全局配置模式，使用 `vlan [VLAN_ID]` 创建 VLAN，并可设置名称：

```plain
Switch> enable  
Switch# configure terminal  
Switch(config)# vlan 10  
Switch(config‑vlan)# name CLIENTS  
Switch(config‑vlan)# exit  
Switch(config)# vlan 20  
Switch(config‑vlan)# name SERVERS  
Switch(config‑vlan)# exit
```

用于逻辑分隔资源组，如客户端与服务器分开管理。

2. **将端口设置为接入 VLAN**  
   将交换机端口划分给特定 VLAN：

```plain
Switch(config)# interface range gigabitEthernet0/1‑4  
Switch(config‑if‑range)# switchport mode access  
Switch(config‑if‑range)# switchport access vlan 10
```

同理为 VLAN 20 设置其他接口。这样连接此端口的设备就属于对应 VLAN。

3. **配置 Trunk 链路（多个 VLAN 共用一条接口）**  
   在交换机之间连接时使用 trunk 模式传递多个 VLAN 并启用 802.1Q 标签模式：

```plain
Switch(config)# interface gigabitEthernet0/24  
Switch(config‑if)# switchport trunk encapsulation dot1q  
Switch(config‑if)# switchport mode trunk
```

这样 trunk 端口能传输多个 VLAN 的流量。

4. **查看 VLAN 配置状态**  
   使用命令查看 VLAN 和端口映射：

```plain
Switch# show vlan brief
```

输出会列出每个 VLAN ID、名称、及其包含的端口。

5. **配置 VLAN 间路由（Switch 或 Router）**  
   若不同 VLAN 之间需要互通，可使用三层交换或路由器，在接口上配置子接口或 SVI（Switch Virtual Interface）方式实现 inter-VLAN routing。

B
