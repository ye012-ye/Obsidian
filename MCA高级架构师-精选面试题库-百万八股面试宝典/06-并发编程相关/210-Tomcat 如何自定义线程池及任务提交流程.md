Tomcat 在内部使用自定义版本的 `ThreadPoolExecutor`，其特点包括提前启动核心线程、使用 `submittedCount` 计数未完成任务，并配合 `TaskQueue` 控制任务入队的策略。

**首先**，线程池在构造时调用 `prestartAllCoreThreads()`，会立刻启动所有核心线程以预热池子，提高响应速度，并初始化如下：

```java
TaskQueue queue = new TaskQueue();
ThreadPoolExecutor executor = new ThreadPoolExecutor(minSpareThreads, maxThreads, 60, TimeUnit.SECONDS, queue, threadFactory);
queue.setParent(executor);
```

M

**然后**，在执行 `execute(Runnable)` 时，会首先 `submittedCount.incrementAndGet()` 增量统计：

```java
submittedCount.incrementAndGet();
try {
    super.execute(command);
} catch (RejectedExecutionException e) {
    // 如果是 TaskQueue，尝试 force 强制入队，否则抛拒绝
    if (!queue.force(command)) {
        submittedCount.decrementAndGet();
        throw e;
    }
}
```

S

**核心逻辑**在于 `TaskQueue.offer(...)` 的特殊判断流程：

- 如果当前线程数已达到 `maximumPoolSize`，则允许入队；
- 如果 `submittedCount <= poolSize`，说明存在空闲线程，也允许入队；
- 否则返回 false，让线程池扩容新线程；
- 最后 fallback 调用 `super.offer(...)` 完成入队。  
  B
