Java 允许将 **任意对象**，包括 `String`，用于 `synchronized(obj)` 块，但 **不建议这样做**。原因在于很多 `String` 对象是复用的，比如字面量或通过 `intern()` 方法获得的，全局共享，容易引发意外的锁冲突甚至死锁。

### 一、为什么不应该锁 `String`

1. **锁对象可能被复用**：Java 自动将字面值字符串或 `intern()` 后的字符串放入全局常量池，多个线程或模块引用同一个内容时可能共享同一锁对象，引发互相阻塞或死锁。
2. **源码中明确警告不匹配同步对象**：CERT 等安全指导建议，绝不应使用可能被复用的对象作为锁，例如 `String`、`Boolean`、`Integer` 等。

### 二、即使调用 `intern()` 也不安全

调用 `synchronized(s.intern())` 确实可以让相同内容字符串的锁对象一致，但是这些对象存在全局共享，仍然可能被代码库其他地方意外同步，导致锁混用或资源竞争。

### 三、安全的替代方案

推荐采用 **私有且独立的锁对象**，确保锁对象唯一、不被其他模块引用：

```java
private final Object lock = new Object();
public void criticalSection() {
    synchronized (lock) {
        // 安全执行
    }
}
```

当需要根据字符串内容动态锁不同资源时，可以使用 **Guava 的** `Interner`，如 `newWeakInterner()`，创建按内容分离但可回收的锁对象，避免内存泄漏和锁冲突：

```java
private static final Interner<String> interner = Interners.newWeakInterner();
synchronized(interner.intern(key)) {
    // keyed 锁
}
```
