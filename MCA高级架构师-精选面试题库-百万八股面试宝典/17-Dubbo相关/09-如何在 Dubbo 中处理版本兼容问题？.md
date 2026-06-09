在 Dubbo 中处理版本兼容性主要依靠 `version` 属性与序列化策略配置，从而支持平滑升级、多版本共存和序列化兼容 ，如下：M

### 使用 `version` 按版本隔离

- 在 Dubbo 中，接口+group+version 是服务的唯一标识。
- **Provider 配置示例**：

```xml
<dubbo:service interface="com.example.UserService"
  ref="userServiceV1" version="1.0.0"/>
<dubbo:service interface="com.example.UserService"
  ref="userServiceV2" version="2.0.0"/>
```

- **Consumer 调用**：

```java
@DubboReference(version="1.0.0") UserService userV1;
@DubboReference(version="2.0.0") UserService userV2;
```

这样就实现了新旧版本并存：新增方法只存在于 V2，不影响旧系统调用 V1。

S

### 2. 序列化协议兼容策略

- Dubbo 从 2.x 到 3.x 默认序列化从 Hessian2 迁移到 Fastjson2。
- 为避免新旧版本因序列化不同而通信失败，提供 `prefer-serialization` 配置：

```properties
dubbo.provider.prefer-serialization=fastjson2,hessian2
```

消费者与提供者会协商共用协议，保证兼容性。B
