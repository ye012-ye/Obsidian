Spring 的事件监听基于观察者模式，其核心是将通信逻辑从组件中剥离，形成发布者与订阅者之间的松散耦合。具体流程如下：

1. **定义事件类**  
   继承 `ApplicationEvent` 或直接使用普通 POJO（自 Spring 4.2 起支持），用于封装事件上下文。M
2. **事件发布者**  
   在需要触发事件的组件中注入 `ApplicationEventPublisher`，通过 `publisher.publishEvent(event)` 发布事件。S
3. **事件监听器**  
   实现 `ApplicationListener<YourEvent>` 接口 或使用 `@EventListener` 注解标注方法。Spring 会根据事件类型自动扫描并回调 `onApplicationEvent(...)` 或目标方法。B
4. **发布-订阅机制**  
   Spring 容器维护监听器注册表，发布事件时根据类型匹配并逐一调用监听器，支持同步与异步处理（结合 `@Async`）。
5. **事务同步支持**  
   使用 `@TransactionalEventListener` 可以指定在事务的某个阶段（如 commit 后）触发监听逻辑，确保数据一致性。

​

**示例：**

```java
public class OrderPlacedEvent extends ApplicationEvent {
    public OrderPlacedEvent(Object source, Order order) {
        super(source); // source typically this
        this.order = order;
    }
    private final Order order;
}
```

```java
@Component
public class OrderService {
    @Autowired
    private ApplicationEventPublisher publisher;

    public void place(Order o) {
        // 准备业务
        publisher.publishEvent(new OrderPlacedEvent(this, o));
    }
}
```

```java
@Component
public class EmailNotifier {
    @EventListener
    public void handle(OrderPlacedEvent evt) {
        // 发送邮件逻辑
    }
}
```

​
