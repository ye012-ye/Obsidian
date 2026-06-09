`ThreadLocal` 为每个线程提供独立变量副本，确保线程之间的变量隔离而无需显式加锁。这种设计非常适合存放线程特有的上下文信息，例如请求ID、数据库连接等。

其核心机制如下：

- 每个 `Thread` 包含一个 `ThreadLocalMap`，以 `ThreadLocal` 对象为键，值为线程副本数据。线程调用 `get()` 与 `set()`，实际上操作的是该 map 中当前线程的数据 S。
- `ThreadLocalMap` 的 key 使用弱引用，value 使用强引用。如果 `ThreadLocal` 实例变得不可达，但 map 中 entry 未被清理，value 仍旧被保留，容易导致内存泄漏。

M

### 常见风险

**内存泄漏** 是最大隐患之一，尤其在使用线程池或 Web 容器时更容易触发：

- 线程池中的线程不会销毁，`ThreadLocalMap` 中的 entry 若未调用 `remove()`，其 value 会长期留存，甚至阻止类加载器卸载，从而导致 PermGen 或 Metaspace 内存泄漏。
- 避免泄漏应在使用结束后 `finally` 中调用 `remove()` 清理线程副本。

S

### 适用场景

- **传递上下文信息**：例如 HTTP 请求的 traceID、用户信息等，在多个处理流程中无需参数传递即可访问。
- **线程安全对象隔离**：如 `SimpleDateFormat`、数据库连接对象，为每个线程提供独立副本，避免锁竞争。
- **事务或缓存上下文**：确保每个线程维护自己的事务状态或一段执行上下文。

B

### 使用示例

```java
static ThreadLocal<SimpleDateFormat> tl = ThreadLocal.withInitial(
    () -> new SimpleDateFormat("yyyy-MM-dd")
);

public static String format(Date date) {
try {
    return tl.get().format(date);
} finally {
    tl.remove(); // 避免内存泄漏
}
}
```
