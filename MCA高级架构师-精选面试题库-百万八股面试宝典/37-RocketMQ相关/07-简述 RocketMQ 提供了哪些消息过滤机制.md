RocketMQ 提供了两种主要的服务器端消息过滤机制：基于 Tag 的过滤和基于属性的 SQL92 过滤。下面分别介绍其实施流程、优缺点和典型使用场景。M

### 1. Tag 过滤（系统属性）

Tag 是附加在每条消息上的系统属性，通常用于标记业务子类型。消费者在订阅时指定所需 Tag，如 `"TagA||TagB"`。Broker 在消息发送时按 Tag 做第一轮过滤，仅将匹配的消息投递给消费者。  
优点是性能高且延迟低，非常适合简单分类需求的业务场景。缺点是每条消息只能有一个 Tag，不支持复杂逻辑。  
Broker 会首先基于 Tag 的 hash 值过滤消息，然后消费者端可能做再一次精确匹配确认。

### 2. SQL92 属性过滤（高级方式）

该机制允许运维人员或开发者在 Broker 启用 `enablePropertyFilter=true` 后，使用 SQL92 语法对消息的自定义属性（如 `region`, `price`）或系统属性 `TAGS` 进行复杂过滤，例如：

```plain
(TAGS IS NOT NULL AND TAGS IN ('TagA','TagB'))
AND (region='HZ' OR price > 100)
```

Broker 会在拉取请求时解析这些 SQL 表达式，只发送满足条件的消息，支持数值比较、逻辑运算等高级过滤。适用于复杂场景，如：根据地域、业务类型、价格区间等多维条件消费。  
缺点是增加了 Broker 端计算开销，配置复杂度高。S

### 使用约束与一致性要求

- SQL92 过滤需要 Broker 启动参数中设置 `enablePropertyFilter=true` 才能生效，同时可配合如 `enableCalcFilterBitMap`, `enableConsumeQueueExt` 等配置进一步优化性能。
- 消费者组中所有实例必须保持一致的订阅表达式，避免因过滤条件不一致造成消息消费遗漏。

B
