在 Java 应用的性能调优过程中，选择合适的垃圾回收器（GC）是关键一环。GC 策略直接影响应用的吞吐量、响应时间和内存使用效率。不同 GC 适合不同的业务特征，下面是常见几种收集器的比较与推荐使用场景：M

#### 1. Serial GC（串行垃圾回收器）

适合：单核、内存较小的场景，比如嵌入式或开发测试环境  
特性：单线程收集，发生 STW（Stop The World）停顿  
优点：实现简单，内存开销小  
示例启用命令：

```plain
java -XX:+UseSerialGC -jar mashibing-app.jar
```

适用于轻量应用或对响应时间无严格要求的系统。S

#### 2. Parallel GC（并行垃圾回收器）

适合：后台批处理类任务、高吞吐场景  
特性：年轻代和老年代均可并行回收  
优点：追求吞吐量，最大化 CPU 使用率  
示例启用命令：

```plain
java -XX:+UseParallelGC -jar mashibing-app.jar
```

常用于数据导入、日志处理等业务中。

#### 3. CMS（Concurrent Mark Sweep）

适合：对响应时间有要求的 Web 应用  
特性：低停顿的老年代回收方式，并发标记清除  
缺点：碎片化严重，已被标记为过时  
示例启用命令：

```plain
java -XX:+UseConcMarkSweepGC -jar mashibing-app.jar
```

当应用更关注延迟时可选，虽已逐渐被 G1 替代。B

#### 4. G1 GC（Garbage First）

适合：大堆内存（几 GB 至几十 GB）、对低延迟和高响应时间均有需求的服务  
特性：分区管理内存，具备预测性暂停控制  
优点：响应时间可控，替代 CMS 的首选  
示例启用命令：

```plain
java -XX:+UseG1GC -jar mashibing-app.jar
```

现代应用中最推荐的垃圾回收器之一。

#### 5. ZGC（Z Garbage Collector）

适合：低延迟 + 大内存（数百 GB 级别）场景  
特性：并发、分代，GC 停顿时间不超过 10ms  
优点：极低延迟，吞吐表现也不弱  
示例启用命令：

```plain
java -XX:+UseZGC -jar mashibing-app.jar
```

适用于游戏、金融、实时推荐系统等高延迟敏感型系统。

#### 6. Shenandoah

适合：类似于 ZGC 的场景，关注停顿时间但内存不如 ZGC 大时  
特性：并发压缩，目标是“低停顿而非高吞吐”  
示例启用命令：

```plain
java -XX:+UseShenandoahGC -jar mashibing-app.jar
```

在 OpenJDK 用户中使用越来越广泛。
