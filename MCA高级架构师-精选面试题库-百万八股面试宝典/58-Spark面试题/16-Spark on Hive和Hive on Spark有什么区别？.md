## **Hive on Spark:**

Hive on Spark是在Hive上新增一种计算引擎Spark，其目的是借助Spark内存计算引擎的优势提升查询Hive数据的性能。默认执行HQL转换成MR，性能慢，底层使用Spark引擎效率高。Hive on Spark与Hive on Tez 、Hive on MR(默认)一样，只是底层执行的引擎不一样而已。

## **Spark on Hive:**

没有官方的Spark on Hive说法，属于大家习惯性的称呼，指的是SparkSQL 读写Hive 表特点场景。SparkSQL可以不读取Hive中的数据，也可以读取Hive中的数据，Spark on Hive目的是让SparkSQL可以访问Hive表，Spark on Hive 就是SparkSQL可以访问Hive表，可以基于SparkSQL构建Hive数仓。

## **Hive on Spark与Spark on Hive异同点：**

**相同点：**SQL执行层都是使用Spark执行引擎。

**不同点有以下3点：**

1. 两者SQL解析层不同，Hive on Spark使用Hive compiler，Spark on Hive 使用的是Spark compiler。
2. Spark on Hive 中 SparkSQL作为Spark生态圈中的一员继续发展，不受限与Hive，只是兼容Hive。
3. Hive on Spark 是Hive中的发展计划，该计划将Spark作为Hive底层引擎之一，Hive 支持引擎除了Spark外还有默认的MR、Tez。
