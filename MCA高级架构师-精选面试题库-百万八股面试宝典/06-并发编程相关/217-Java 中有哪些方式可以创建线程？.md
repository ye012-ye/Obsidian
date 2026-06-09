在 Java 中创建线程的常用方式如下，每种方式的适用场景和代码简洁度各有区别，都可以根据实际需求选用。

### 1. 继承 `Thread` 类

通过继承 `Thread` 并重写 `run()` 方法，将任务逻辑写入其中，然后调用 `start()` 启动线程。这种方式简单直观，但存在单继承的限制，不适合复合型任务结构。

**示例**：

```java
class MyThread extends Thread {
    @Override
    public void run() {
        // 任务逻辑
    }
}
MyThread t = new MyThread();
t.start();
```

### 2. 实现 `Runnable` 接口

最常见的方式：实现 `Runnable` 接口并在 `run()` 中定义任务，将其传递给 `Thread` 构造器，然后调用 `start()`。这种方式解耦逻辑与线程，更灵活。

### 3. 匿名内部类

若任务逻辑简单，可使用匿名内部类创建线程。这提高了代码的局部性和可读性，特别适合一次性任务。

### 4. Lambda 表达式（Java 8+）

使用 Lambda 表达式实现 `Runnable`，使代码更加简洁，适用于纯函数式的任务逻辑。逻辑清晰，代码量少。

**示例**：

```java
new Thread(() -> {
    // 任务逻辑
}).start();
```

### 5. 使用线程池（Executor 框架）

推荐在生产环境中广泛使用，通过 `ExecutorService`（如 `ThreadPoolExecutor`）管理线程生命周期和任务调度。适合大批量任务提交、复用线程资源并控制并发度。

### 6. 虚拟线程（Virtual线程，Java 19+）

Java 19‑21 引入虚拟线程，极其轻量，可以实例化百万级线程而资源占用极低。可以通过如下方式创建虚拟线程：

- `Thread.ofVirtual().start(runnable)` 或 `Thread.ofVirtual().unstarted(runnable)`
- 或使用 `Executors.newVirtualThreadPerTaskExecutor()` 获取虚拟线程 executor。

**示例**：

```java
Thread vt = Thread.ofVirtual().start(() -> {
    // 任务逻辑
});
```

或

```java
ExecutorService exec = Executors.newVirtualThreadPerTaskExecutor();
exec.submit(() -> { /* 任务 */ });
```

虚拟线程非常适合 I/O 密集型场景，通过 JVM 调度分配，实现高并发。

## 对比

|  |  |  |  |
| --- | --- | --- | --- |
| **方法** | **代码简洁性** | **灵活性** | **并发性能** |
| 继承 `Thread` | 中等 | 较差 | 通常较低 |
| 实现 `Runnable` | 良好 | 较好 | 中等 |
| 匿名类 / Lambda | 简洁 | 灵活 | 中等 |
| 线程池 | 可控性高 | 高（复用、限流） | 良好 |
| 虚拟线程 | 简单易用 | 极高（可百万级任务） | 优异（I/O 密集场景） |
