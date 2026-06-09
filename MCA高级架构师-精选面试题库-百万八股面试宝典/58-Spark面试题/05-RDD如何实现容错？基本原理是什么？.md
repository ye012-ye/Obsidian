Spark RDD实现容错主要有三个层次实现:任务调度层、RDD Lineage血统层、Checkpoint数据持久化层。

## **任务调度层：**

Spark任务调度过程中如果task执行失败，TaskScheduler会进行重试执行，默认重试4次（spark.task.maxFailures）后依然失败，DAGScheduler会进行重试Stage，默认重试4次（spark.stage.maxConsecutiveAttempts）后如果失败，整个Spark Job执行失败。

以上任务调度层的重试会针对当前task处理的数据进行重算，保证RDD容错。

## **RDD Lineage血统层：**

Spark RDD之间是有依赖关系的，子RDD通过Transformation类算子基于父RDD生成，形成Lineage血统链，在计算过程中如果节点宕机或者使用到RDD数据而该数据又没有缓存时可以通过Lineage重新计算生成。RDD之间的依赖关系分为窄依赖和宽依赖，这些依赖形成的Lineage可以保证RDD的容错性。

在窄依赖中，父RDD分区与子RDD分区是一对一的关系或者多对一的关系，重算子RDD数据时由于父RDD相应分区的数据都是子RDD分区的数据，只需要计算父RDD对应分区的数据即可，不存在冗余计算。在宽依赖中，丢失一个RDD分区数据需要重算每个父RDD的每个分区的所有数据，这些重算的结果可能只有一部分属于子RDD，这样就产生了冗余计算开销。

可见，在通过RDD依赖关系保证RDD容错过程中，**RDD宽依赖的开销比RDD在依赖的开销要大的多。**

## **Checkpoint数据持久化层：**

针对宽依赖开销大的问题我们可以针对RDD设置checkpoint检查点，这样就能将RDD的数据持久化到磁盘上，在子RDD重新计算过程中就不必从源头开始计算，而是基于checkpoint的数据开始计算即可，尤其是对宽依赖的RDD设置checkpoint 可以大大提升RDD恢复效率。

对于checkpoint的使用，建议在以下两种情况可以考虑：

- **DAG Lineage 过长，如果重算则开销很大**
- **在Shuffle RDD上设置checkpoint可以避免冗余计算，收益更大**

对RDD执行checkpoint之前，最好对这个RDD先执行cache，这样新启动的job只需要将内存中的数据持久化到磁盘即可省去了重新计算这一步。
