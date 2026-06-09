要在 Dubbo 中实现跨集群或跨数据中心的透明服务调用，可采用“多注册中心 + 注册表分组 + 负载策略”三步法：

### 一、多注册中心配置

在项目的配置文件（如 Spring Boot 的 `application.yml` 或 XML）中定义多个注册中心，示例：

```yaml
dubbo:
  registries:
    beijing:
      address: zookeeper://zk-beijing:2181
    shanghai:
      address: zookeeper://zk-shanghai:2181
```

默认情况下，服务会注册到所有全局注册中心。也可使用 `default: true/false` 控制是否作为默认注册中心进行注册或订阅。

### 二、服务发布/订阅关联注册中心

通过 XML 或注解方式，为服务明确指定注册中心：

```xml
<dubbo:service interface="com.example.OrderService"
  ref="orderServiceImpl"
  registry="beijing,shanghai"/>
<dubbo:reference id="orderClient"
  interface="com.example.OrderService"
  registry="beijing,shanghai"/>
```

这样，Provider 会在两个中心注册；Consumer 也会从两个中心订阅，实现跨集群调用。

M

### 三、选择注册中心的调用调度策略

Dubbo 在 Consumer 通过注册中心获取 Provider 列表后，会执行两层选择流程：

1. **注册中心层**, 可设置属性如 `preferred=true`、`weight=50` 倾斜访问优先集群，B
2. **服务节点层**, 则使用负载算法（如轮询、随机、最少活跃调用）选择具体实例。

例如：

```xml
<dubbo:registry id="beijing" address="..." preferred="true" weight="80"/>
<dubbo:registry id="shanghai" address="..." weight="20"/>
```

以上配置意味着优先访问北京集群，上海集群作为降级备选。

### 四、调用示例

Consumer 使用与本地调用一致的接口即可，无需做集群差异判断：

```java
orderClient.createOrder(...);
orderClient.queryStatus(...);
```

Dubbo 框架会根据上述配置完成跨集群调用，避免业务侧代码的复杂性。S
