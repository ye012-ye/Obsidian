在 Java 并发优化中，通过合理配置 `ThreadPoolExecutor` 的关键参数可以显著提升性能和资源利用效率：

首先，根据任务性质与业务瓶颈确定**线程池大小（核心线程数与最大线程数）**。推荐使用如下公式：

```plain
线程数 ≈ CPU 核心数 × (1 + 等待时间 / 服务时间)
```

其中等待时间主要包括 I/O、锁等待等，而服务时间是 CPU 执行时间。I/O 密集型任务可适当提升线程数，CPU 密集型任务则与 CPU 核数相当即可。

其次，**合理选择任务队列类型**：

- 对于 CPU 密集型任务，可选用容量适当的有界队列，避免过度排队延迟增加。
- 对 I/O 密集型任务，可使用无界队列避免任务拒绝。

第三，**调优线程存活时间（keepAliveTime）**：  
允许线程在空闲一段时间后退出，以释放资源；但若任务频繁且系统资源充足，可以延长存活时间，减少线程频繁创建销毁的开销。

第四，**自定义 ThreadFactory 与拒绝策略**：  
通过线程工厂设置线程名称、优先级、是否为守护线程，提高可维护性与调试能力；同时自定义拒绝策略（如抛异常、记录日志或重试提交），保障任务在队列满或线程饱和时得到妥善处理。

第五，**减少竞争与上下文切换**：  
尽量使用并发安全数据结构（Atomic、ConcurrentHashMap 等）和非阻塞算法，缩小 synchronized 区域或采用读写锁，降低锁竞争带来的性能损耗。

第六，**按任务类型使用多个线程池**：  
针对不同性质（如 CPU 密集、I/O 密集、定时调度等）的任务，分别配置独立线程池，可更精准调优参数而避免单一池参数难兼顾多样负载。

### 综合示例框架：

```java
int cores = Runtime.getRuntime().availableProcessors();
double blockingCoeff = waitTime / serviceTime;
int poolSize = (int)(cores * (1 + blockingCoeff));

ThreadPoolExecutor executor = new ThreadPoolExecutor(
    corePoolSize, maxPoolSize, keepAliveTime, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(queueCapacity),
    customThreadFactory, customRejectedHandler);
```

### 总结：通过科学地确定线程数、队列类型、线程存活时长，以及使用线程工厂、拒绝处理、自定义线程池分离任务类型等手段，可以高效提升 Java 线程池的性能与系统吞吐能力。同时，要结合负载测试、指标监控不断调优，切忌盲目猜测。
