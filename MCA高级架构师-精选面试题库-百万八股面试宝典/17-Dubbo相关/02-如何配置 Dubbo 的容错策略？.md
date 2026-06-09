Dubbo 的容错策略是通过 `cluster` 属性控制调用失败后的处理行为，不同策略适用于不同场景。以下是六种常见策略：

### 1. Failover（失败自动切换）

- **行为**：调用失败后自动切换到其它可用提供者并重试。Dubbo 默认配置。
- **配置示例（XML、注解）**：

```xml
<dubbo:reference id="svc" interface="Xxx" cluster="failover" retries="2"/>
```

或

```xml
@DubboReference(cluster = "failover", retries = 2)
private XxxSvc svc;
```

- **适用场景**：适合读请求，供方临时出错，但对延迟容忍。

M

### 2. Failfast（快速失败）

- **行为**：调用失败立即报错，不重试。
- **配置示例**：

```xml
<dubbo:reference interface="Xxx" cluster="failfast"/>
```

- **适用场景**：重要写操作，如银行下单、创建记录，避免重复副作用。

### 3. Failsafe（失败安全）

- **行为**：失败时吞掉异常，返回默认值。
- **配置示例**：

```xml
<dubbo:reference interface="Xxx" cluster="failsafe"/>
```

- **适用场景**：非关键操作，如日志记录、下线通知。

S

### 4. Failback（失败自动恢复）

- **行为**：记录失败请求，后台定时重发。
- **配置示例**：

```xml
<dubbo:reference interface="Xxx" cluster="failback"/>
```

- **适用场景**：通知类任务，如消息推送、异步消息。

### 5. Forking（并行调用）

- **行为**：并行调用多个提供者，任一成功即返回。
- **配置示例**：

```xml
<dubbo:reference interface="Xxx" cluster="forking" forks="2"/>
```

- **适用场景**：高实时要求的读操作，但会消耗更多资源。

B

### 6. Broadcast（广播调用）

- **行为**：请求发送到所有提供者，任一失败则整个调用失败。
- **配置示例**：

```xml
<dubbo:reference interface="Xxx" cluster="broadcast" broadcast.fail.percent="20"/>
```

- **适用场景**：更新各节点缓存或配置，确保一致性。

### 配置优先级与方式

- **XML/Java 注解配置**：通过 `<dubbo:reference cluster="..." ...>` 或 `@DubboReference(cluster="...")` 设置。
- **优先级**：方法 > 接口，消费者侧优先于提供者侧。
- **推荐配置方式**：在消费者端明确容错策略，不依赖提供方配置。
