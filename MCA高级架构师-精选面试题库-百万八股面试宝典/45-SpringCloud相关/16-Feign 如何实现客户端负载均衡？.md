Feign 默认集成 Ribbon 实现客户端负载均衡，具体流程如下：

### 1. 引入 Ribbon 依赖与开启 Feign

- 在 Spring Cloud 项目中，引入 `spring-cloud-starter-netflix-ribbon` 和 `spring-cloud-starter-openfeign`；
- 添加 `@EnableFeignClients`、使用 `@FeignClient(name="service-name")` 注解即可自动启用 Ribbon 作为 Feign 的客户端负载均衡组件。  
  FeignClient 被封装为 `LoadBalancerFeignClient`，内部会调用 Ribbon 的 `ILoadBalancer` 和 `ServerList`。

### 2. 获取可用服务实例列表

- Ribbon 在客户端启动或首次调用时，从服务注册中心（如 Eureka、Nacos）获取服务实例列表；
- 每个命名的 Feign 客户端会创建一个 Ribbon 客户端上下文（`RibbonClientConfiguration`），包括 `ServerList`、`Rule`、`ILoadBalancer` 等组件。
- 也可以通过 `@RibbonClient(name = "service-name", configuration = MyConfig.class)` 自定义 Ribbon 行为。

### 3. 负载均衡策略和请求分发逻辑

- 在发送 Feign 请求时，它通过 Ribbon 的负载均衡规则（如轮询、随机、加权、响应时间优先）选出具体实例；
- Ribbon 会检测实例健康状态，若发现不可用实例，则从服务列表中剔除并重新拉取。
- 然后，Feign 通过选定实例的 IP + port 发起 HTTP 调用，实现真正意义上的客户端负载均衡。

### 4. 配置与自定义扩展能力

- 可通过配置文件指定 Ribbon 行为，例如：

```properties
service-name.ribbon.listOfServers=http://host1:port,http://host2:port
service-name.ribbon.NFLoadBalancerRuleClassName=com.my.CustomRule
```

- 使用 `@RibbonClient` 注入自定义配置类覆盖默认负载均衡规则、健康检查器、ServerList 等。
