`CountDownLatch` 是 Java 并发工具，用于协调一个或多个线程等待若干事件完成后继续执行。其核心原理和用法如下：M

#### 1. 基本原理与机制

- **计数器**：在构造时设置初始值 count，表示要等待的事件数或线程数
- **countDown()**：每次被调用，计数减一；当计数器减至 0 时，所有通过 `await()` 阻塞的线程被释放
- **await()**：当前线程阻塞，直到计数降为 0 或线程被中断；也支持超时版本 `await(timeout, unit)`

S

#### 2. 典型使用场景

- **多线程并发启动**：例如多个服务或子任务启动完成后，主线程再继续执行
- **任务拆分等待**：将大任务拆为多个子任务并发执行，主线程等待所有完成再汇总处理
- **测试并发边界**：通过 `CountDownLatch(1)` 控制线程同时开始，以复现并发问题

B

#### 3. 样例代码

```java
CountDownLatch latch = new CountDownLatch(3);
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        // do work...
        latch.countDown();
    }).start();
}
latch.await();
System.out.println("Ok, all done");
```
