在 Dubbo 中，服务消费者可以通过 XML 或注解两种方式来配置对提供方接口的引用，重点可以放在版本控制、超时设置和重试逻辑上。下面详细说明两种做法：

### 1. XML 配置方式

在 Spring 的 XML 配置中，通过 `<dubbo:reference>` 标签设置消费者引用：

```xml
<beans xmlns="http://www.springframework.org/schema/beans"
  xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
  xsi:schemaLocation="http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

  <!-- 应用及注册中心 -->
  <dubbo:application name="consumer-app" />
  <dubbo:registry address="zookeeper://127.0.0.1:2181" />

  <!-- 引用配置 -->
  <dubbo:reference id="demoSvc" interface="com.example.DemoService"
    version="1.0.0" timeout="3000" retries="2">
    <dubbo:method name="queryUser" timeout="2000" retries="0" />
  </dubbo:reference>
</beans>
```

- `version`: 标识服务版本，用于区分多个版本实例。S
- `timeout`: 全局调用超时，单位毫秒。B
- `retries`: 全局调用失败后重试次数（不含首次调用）。
- `<dubbo:method>` 子标签可针对某一方法单独指定 timeout 和 retries，优先级高于接口级配置。M

配置优先级顺序为：方法级 > 接口级 > 全局配置，且消费者一侧优先于提供方配置。

### 2. 注解方式

在 Spring 组件中使用 `@Reference` 或 `@DubboReference` 注解配置：

```java
@Component
public class DemoConsumer {
    @DubboReference(interfaceClass = DemoService.class,
                    version = "1.0.0",
                    timeout = 3000,
                    retries = 2,
                    methods = {
                        @Method(name = "queryUser", timeout = 2000, retries = 0)
                    })
    private DemoService demoService;
}
```

- 与 XML 的属性相同，且方法级配置使用 `methods` 数组指定。
- 注解方式与 XML 功能等效，内部也是通过 ReferenceConfig 实现解析。

特别注意：方法级配置（无论 XML 或注解）优先于接口级，同级中消费者定义优于提供者定义；如果只配置接口级或全局配置，则所有方法都应用该配置。
