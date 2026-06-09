AQE 自适应查询配置参数如下:

- **spark.sql.adaptive.enabled**

默认true，当为true时，启用AQE自适应查询，它将基于准确的运行时统计信息，在查询执行过程中重新优化查询计划。

- **spark.sql.adaptive.advisoryPartitionSizeInBytes**

在SparkSQL AQE中自动分区合并后分区大小，默认为64M。该参数也可以有效避免SparkSQL中小文件产生。建议可以设置成为dfs.block.size的大小，这样可以做到和块对齐。

- **spark.sql.adaptive.autoBroadcastJoinThreshold**

SparkSQL AQE中自动将小于该配置参数的表进行广播，默认值与spark.sql.autoBroadcastJoinThreshold相同为10M，如果配置成-1,表示禁用广播。

- **spark.sql.adaptive.coalescePartitions.enabled**

默认为true，Spark将根据目标大小(由' spark .sql.adaptive. advisorypartitionsizeinbytes '指定)合并连续的shuffle分区，以避免太多的小任务。

- **spark.sql.adaptive.coalescePartitions.initialPartitionNum**

SparkSQL AQE自动合并分区中，启动自动分区合并的shuffle分区的初始数目，默认与spark.sql.shuffle.partitions相同，此配置仅在“spark.sql.adaptive”为true且“spark.sql.adaptive.coalescePartitions”为true下生效。

- **spark.sql.adaptive.coalescePartitions.minPartitionSize**

SparkSQL AQE自动分区合并中，合并后shuffle分区的最小大小，默认1M。分区自动合并后最小分区大小不小于该值。

- **spark.sql.adaptive.optimizeSkewsInRebalancePartitions.enabled**

SparkSQL AQE中是否将倾斜分区数据拆分成更小的分区进行倾斜处理，默认true。

- **spark.sql.adaptive.skewJoin.skewedPartitionFactor**

SparkSQL AQE中如何认定分区是有数据倾斜的膨胀系数，默认为5。如果一个分区数据量大小大于所有task处理数据量中位数的5倍并且大于spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes参数时，认为该分区存在数据倾斜。

- **spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes**

SparkSQL AQE中认定一个分区是有数据倾斜的大小值，默认256M。如果一个分区大小超过该值并且满足spark.sql.adaptive.skewJoin.skewedPartitionFactor指定的因子数，则认为该分区存在数据倾斜。

- **spark.sql.adaptive.skewJoin.enabled**

SparkSQL AQE 中，Spark通过拆分或者复制倾斜分区数据来动态处理倾斜连接，默认为true。
