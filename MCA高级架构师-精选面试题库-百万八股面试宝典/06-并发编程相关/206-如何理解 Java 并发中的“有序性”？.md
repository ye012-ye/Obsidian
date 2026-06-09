Java 并发中的 **有序性** 指的是程序在多线程执行时，实际执行顺序应符合程序设计的预期顺序。然而，由于 **编译器、JIT、CPU** 或 **缓存系统** 为了性能优化会对指令进行重排序，使得程序实际执行顺序可能与源代码顺序不一致，这正是有序性问题的来源。JMM（Java 内存模型）通过 **happens-before 规则** 来校正这种顺序偏差，保证跨线程正确的执行效果。

在多线程并发环境下，如果没有合适的同步机制，指令重排可能导致线程之间看到中间或错误状态。例如，在双重检查锁模式（DCL）中：

```java
if (instance == null) {
    synchronized (Singleton.class) {
        if (instance == null) {
            instance = new Singleton();
        }
    }
}
```

编译器或 CPU 可能进行如下重排序后执行：

1. 分配内存
2. 将引用赋值给 `instance`（此时对象尚未初始化）
3. 执行初始化构造逻辑

若此时 `instance` 尚未标记为 `volatile`，线程 B 在检测 `instance != null` 时可能拿到一个尚未初始化完成的对象引用，导致不确定行为。

### 保证有序性的方式

**1. 使用** `volatile` **修饰共享变量**  
`volatile` 不仅保证可见性，还提供 **写-读屏障（release/acquire）** 语义，阻止写前后或读取/写入的重排序，从而确保写入完成后，后续读能正确获取到值，防止DCL等操作因重排序失败。

**2. 使用** `synchronized` **或** `Lock`  
加锁和解锁操作建立了 happens-before 关系，即解锁操作的效果对后续获取锁的线程是可见的，并且锁内的代码段不会发生重排序，常用于构建安全的初始化逻辑或保证多个操作的顺序完整性。

### 示例代码

```java
class Singleton {
    private volatile static Singleton instance;
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // 这一步不会被重排序到赋值前
                }
            }
        }
        return instance;
    }
}
```

在以上代码中，`volatile` 保证对 `instance` 的写操作不会与构造函数体重排，从而避免线程拿到未构造完成的对象。
