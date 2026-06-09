在 Java 中要确保 T1、T2、T3 严格按顺序执行，可以使用以下几种可靠的方式，每种方法都有其适用场景和特点。

### ​方法一：使用 `Thread.join()` 链式控制

最直接且简单的方法是通过 `join()` 方法建立线程间的依赖关系，让后一个线程在其 `run()` 方法里等待前一个线程结束。

例如可以让 T2 在其 `run()` 中调用 `T1.join()`，T3 中调用 `T2.join()`。也有另一种方式是在主线程中先启动 T1 并等待结束（`join()`），接着启动 T2 并等待，最后启动 T3。这种方式代码清晰，容易理解，适用于确定启动顺序且不追求并发重叠的场景。

### 方法二：使用 `CountDownLatch` 控制顺序

借助两个 `CountDownLatch`（latch1 和 latch2），让 T2 等待 latch1 到达 0（由 T1 完成后 `countDown()`），T3 等待 latch2 到达 0（由 T2 完成后 `countDown()`）。这种方式无需在多个线程内部加入 `join()` 串联，结构清晰，适合线程间协调控制。

### 方法三：使用 `wait()`/`notifyAll()` 机制

通过共享锁与状态变量（如 `currentThreadId`），每个线程在获取锁后，检查是否轮到自己执行，不是则 `wait()`；执行完后修改顺序变量并调用 `notifyAll()` 通知其他线程。这种方式适用于循环调度或可重用情景，但需注意避免线程唤醒策略带来的复杂性。

### 方法对比

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **方法** | **执行顺序可控性** | **简洁程度** | **并发利用** | **推荐场景** |
| `join()` | 强 | 高 | 低 | 简单串联执行 |
| `CountDownLatch` | 高 | 中等 | 可用中继 | 需要协调启动控制 |
| `wait()/notify()` | 高 | 低 | 高 | 强控制、复杂同步逻辑 |

### 示例代码（`join()` 方式）

```java
Thread t1 = new Thread(() -> {
    System.out.println("T1 执行");
});
Thread t2 = new Thread(() -> {
    try { t1.join(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    System.out.println("T2 执行");
});
Thread t3 = new Thread(() -> {
    try { t2.join(); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    System.out.println("T3 执行");
});

t1.start();
t2.start();
t3.start();
```
