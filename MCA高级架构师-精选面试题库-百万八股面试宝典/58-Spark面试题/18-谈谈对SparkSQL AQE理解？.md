SparkSQL执行过程中虽有一系列的优化，但是存在以下几个问题：

1. **SparkSQL 不能选出最优的查询计划**

SparkSQL支持RBO和CBO查询优化器对SQL进行优化得到最优查询计划，RBO生成的查询计划不一定最优，虽然SparkSQL支持CBO获取最优查询计划，但CBO仅支持注册到Hive Metastore的数据表，对于读取分布式文件这种场景不支持CBO，此外，CBO一旦获取最优的查询计划交付运行后，在Spark任务运行过程中，提交的查询计划不能进行修改，在这个层次上来说，CBO也相当于是一种静态的优化策略，往往SparkSQL任务运行过程中会涉及多个Stage阶段，每个阶段会涉及数据shuffle数据落盘，这些数据在后续阶段处理过程中再使用CBO优化选择出执行计划可能并不是最优。

2. **SparkSQL默认支持固定的Shuffle分区数**

在SparkSQL中可以通过spark.sql.shuffle.partitions来设置SQL任务执行过程中的分区数，默认为200,该参数决定了“reduce task”个数。当我们配置了该参数后会默认给当前SparkSQL任务所有的join或者聚合操作设置了统一的分区数，相同的shuffle分区数不能适合单个查询的所有stage，因为每个stage都有不同的输出数据大小和分配。

例如：通过SQL对数据进行了过滤，这时我们需要调小该参数以防止增加调度开销和小reduce任务、小文件的产生；但是如果该值设置太小又不能满足前面一些阶段数据处理要求，可能出现一个task处理的数据量非常多，导致频繁的GC，甚至出现OOM问题。

所以，shuffle 分区数既不能太小也不能太大。为了获得最佳性能，我们经常需要在非生产环境中为多次调整 shuffle 分区数。

3. **数据倾斜影响SparkSQL稳定性**

SparkSQL处理过程中也会出现数据倾斜问题，一些数据对应的key数据量非常大，与其他数据进行关联时，经过hash分区相同key被同一个task处理，导致该task执行时间长，影响整体性能，甚至一些task在倾斜过程中拉取倾斜数据时，导致executor内存OOM。当然我们也可以对倾斜的key进行“加盐”处理，但在SparkSQL真正任务执行之前增加了任务复杂性。

## **AQE自适应查询**

针对以上SparkSQL执行过程中的缺点问题，Spark 3.0 推出了 AQE (Adaptive Query Execution，自适应查询执行)，AQE 是 Spark SQL 的一种动态优化机制，在运行时，**每当 Shuffle Map 阶段执行完毕，AQE 都会结合这个阶段的统计信息，基于既定的规则动态地调整、修正尚未执行的逻辑计划和物理计划，来完成对原始查询语句的运行时优化。**

**Spark Shuffle 的每个 Map Task 会输出中间文件,AQE 依赖Shuffle Map 阶段输出的中间文件的统计信息，如每个 shuffle data 文件的大小、空文件数量与占比、每个 Reduce Task 对应的分区大小等。AQE 优化机制触发的时机是 Shuffle Map 阶段执行完毕，如果没有 Shuffle AQE 就不会触发。**

## **AQE 特点**

1. **优化Shuffle过程，自动分区合并**

AQE 会自动合并过小的数据分区。Shuffle 后，在 Reduce 阶段，当 Reduce Task 把数据分片从map端拉回，AQE 按照分区编号的顺序，依次把小于目标尺寸的分区合并在一起。

AQE 实现了动态调整 shuffle partition 个数机制，在运行不同stage的时候，会根据 map 端 shuffle write 的实际数据量，来决定启动多少个 reducer 来处理，这样无论数据量怎么变换，都可以通过不同的 reducer 个数来均衡数据，从而保证单个 reducer 拉取的数据量不至于太大。但AQE 并清楚 map 端需要对数据分出来多少份，所以实际使用的时候，可以把 spark.sql.shuffle.partitions 参数往大了设置。

2. **调整Join策略,自动广播**

SparkSQL两表进行Join关联时，为了能提高join性能我们可以将一张表进行广播后与另外一张表进行Join。AQE 中，会在运行时根据真实的数据来进行判断，当其中一个join表的实际大小小于spark.sql.autoBroadcastJoinThreshold阈值时（默认10M），就会把执行计划中的 shuffle join 动态修改为 broadcast join。

3. **自动倾斜处理**

在AQE中，通过收集运行时统计信息，我们就可以动态探测出倾斜的分区，从而对倾斜的分区，分裂出来子分区，每个子分区对应一个 reducer， 从而缓解数据倾斜对性能的影响。AQE 自动拆分 Reduce 过大的数据分区，降低单个 Reduce Task 的工作负载。
