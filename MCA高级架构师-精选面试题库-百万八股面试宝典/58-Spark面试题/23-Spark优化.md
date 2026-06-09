## **资源优化**

1. **在搭建Spark集群时给定Spark集群充足的资源（core+内存），可以通过配置Spark 安装包的conf下spark-env.sh 实现。**

|  |
| --- |
| SPARK\_WORKER\_CORES  SPARK\_WORKER\_MEMORY  SPARK\_WORKER\_INSTANCE |

2. **在提交Application的时候给Application分配更多的资源。**

|  |
| --- |
| #提交命令选项：（在提交Application的时候使用选项）  --executor-cores  --executor-memory  --total-executor-cores    #配置信息：（在Application的代码中设置，在Spark-default.conf中设置）  spark.executor.cores  spark.executor.memory  spark.max.cores |

3. **开启动态资源配置**

Spark中可以通过指定“spark.executor.instances”（--num-executors）来指定一个Spark应用使用的executor数量，但是该值无论Spark数据量是多是少都会使用这些executor直到Spark Application结束，如果对于数据增长过快的Spark任务，可以使用动态资源，限定Application使用的Executor个数。

此外，一个 Spark Application中如果一些 Stage 有数据倾斜，可能会有一些 Executor 是空闲状态，造成集群资源的极大浪费，通过动态资源分配策略，已经空闲的 Executor 如果超过了一定时间，就会被集群回收，并在之后的 Stage 需要时可再次请求 Executor，真正做到按需使用资源。

动态资源分配参数如下：

- **spark.dynamicAllocation.enabled**

是否开启动态资源配置，根据工作负载来衡量是否应该增加或减少executor，默认false。开启此参数需要设置spark.shuffle.service.enabled或者spark.dynamicAllocation.shuffleTracking.enabled为true。

- **spark.shuffle.service.enabled**

是否开启External Shuffle Service服务,默认false。executor在运行过程中除了负责运行task，还需要写shuffle数据，这样有可能导致executor 进程任务过重，影响task运行，导致无法向外提供数据，这时可以开启External Shuffle Service服务，该服务是运行于NodeManager进程中的一个服务，通过该服务可以抓取shuffle数据向外提供shuffle数据，提升shuffle计算性能。

- **spark.dynamicAllocation.shuffleTracking.enabled**

spark3新增，启用shuffle文件跟踪，此配置不会回收保存了shuffle数据的executor。默认为true。

- **spark.dynamicAllocation.executorIdleTimeout**

启动动态资源分配后，当某个executor空闲超过这个设定值，就会被kill，默认60s。

- **spark.dynamicAllocation.minExecutors**

动态分配最小executor个数，在启动时就申请好的，默认0。

- **spark.dynamicAllocation.maxExecutors**

动态分配最大executor个数，默认infinity无穷大。

- **spark.dynamicAllocation.initialExecutors**

动态分配初始executor个数默认值=spark.dynamicAllocation.minExecutors，如果设置了--num-executors 或 spark.executor.instances 并且大于这个值，该值被用作启动Executor的初始数量。

- **spark.dynamicAllocation.schedulerBacklogTimeout**

如果启用了动态分配，并且有待解决的任务积压的时间超过了此期限，则将请求新的executor，默认1s。(第一次申请)

- **spark.dynamicAllocation.sustainedSchedulerBacklogTimeout**

与spark.dynamicAllocation.schedulerBacklogTimeout相同，但仅用于后续Executor请求的间隔时间。(第二次及以后)

## **并行度优化**

原则：一个core一般分配2~3个task,每一个task一般处理1G数据（task的复杂度类似wc）

提高并行度的方式：

- sc.textFile(xx,minnumpartition)
- sc.parallelize(xx,num)
- sc.makeRDD(xx,num)
- sc.parallelizePairs(xx,num)
- reduceByKey,join,distinct
- repartition/coalesce
- spark.default.parallelism
- spark.sql.shuffle.partitions
- 自定义分区器

## **代码优化**

1. **避免创建重复的RDD，复用同一个RDD**
2. **对多次使用的RDD进行持久化**

如何选择一种最合适的持久化策略？

默认情况下，性能最高的当然是MEMORY\_ONLY，但前提是你的内存必须足够足够大，可以绰绰有余地存放下整个RDD的所有数据。因为不进行序列化与反序列化操作，就避免了这部分的性能开销；对这个RDD的后续算子操作，都是基于纯内存中的数据的操作，不需要从磁盘文件中读取数据，性能也很高；而且不需要复制一份数据副本，并远程传送到其他节点上。但是这里必须要注意的是，在实际的生产环境中，恐怕能够直接用这种策略的场景还是有限的，如果RDD中数据比较多时（比如几十亿），直接用这种持久化级别，会导致JVM的OOM内存溢出异常。

如果使用MEMORY\_ONLY级别时发生了内存溢出，那么建议尝试使用MEMORY\_ONLY\_SER级别。该级别会将RDD数据序列化后再保存在内存中，此时每个partition仅仅是一个字节数组而已，大大减少了对象数量，并降低了内存占用。这种级别比MEMORY\_ONLY多出来的性能开销，主要就是序列化与反序列化的开销。但是后续算子可以基于纯内存进行操作，因此性能总体还是比较高的。此外，可能发生的问题同上，如果RDD中的数据量过多的话，还是可能会导致OOM内存溢出的异常。

如果纯内存的级别都无法使用，那么建议使用MEMORY\_AND\_DISK\_SER策略，而不是MEMORY\_AND\_DISK策略。因为既然到了这一步，就说明RDD的数据量很大，内存无法完全放下。序列化后的数据比较少，可以节省内存和磁盘的空间开销。同时该策略会优先尽量尝试将数据缓存在内存中，内存缓存不下才会写入磁盘。

通常不建议使用DISK\_ONLY和后缀为\_2的级别：因为完全基于磁盘文件进行数据的读写，会导致性能急剧降低，有时还不如重新计算一次所有RDD。后缀为\_2的级别，必须将所有数据都复制一份副本，并发送到其他节点上，数据复制以及网络传输会导致较大的性能开销，除非是要求作业的高可用性，否则不建议使用。

持久化算子：

- cache:MEMORY\_ONLY
- persist：MEMORY\_ONLY、MEMORY\_ONLY\_SER、MEMORY\_AND\_DISK\_SER。一般不要选择带有\_2的持久化级别。
- checkpoint:如果一个RDD的计算时间比较长或者计算起来比较复杂，一般将这个RDD的计算结果保存到HDFS上，这样数据会更加安全。如果一个RDD的依赖关系非常长，也会使用checkpoint,会切断依赖关系，提高容错的效率。

3. **尽量避免使用shuffle类的算子**

使用广播变量来模拟使用join,使用情况：一个RDD比较大，一个RDD比较小。

join算子=广播变量+filter、广播变量+map、广播变量+flatMap

4. **使用map-side预聚合的shuffle操作**

即尽量使用有combiner的shuffle类算子。combiner概念：在map端，每一个map task计算完毕后进行的局部聚合。

combiner好处：

- 降低shuffle write写磁盘的数据量。
- 降低shuffle read拉取数据量的大小。
- 降低reduce端聚合的次数。

有combiner的shuffle类算子：

- reduceByKey:这个算子在map端是有combiner的，在一些场景中可以使用reduceByKey代替groupByKey。
- aggregateByKey
- combineByKey

5. **尽量使用高性能的算子**

- 使用reduceByKey替代groupByKey
- 使用mapPartition替代map
- 使用foreachPartition替代foreach
- filter后使用coalesce减少分区数
- 使用使用repartitionAndSortWithinPartitions替代repartition与sort类操作
- 使用repartition和coalesce算子操作分区。

6. **使用广播变量**

开发过程中，会遇到需要在算子函数中使用外部变量的场景（尤其是大变量，比如100M以上的大集合），那么此时就应该使用Spark的广播(Broadcast）功能来提升性能，函数中使用到外部变量时，默认情况下，Spark会将该变量复制多个副本，通过网络传输到task中，此时每个task都有一个变量副本。如果变量本身比较大的话（比如100M，甚至1G），那么大量的变量副本在网络中传输的性能开销，以及在各个节点的Executor中占用过多内存导致的频繁GC，都会极大地影响性能。如果使用的外部变量比较大，建议使用Spark的广播功能，对该变量进行广播。广播后的变量，会保证每个Executor的内存中，只驻留一份变量副本，而Executor中的task执行时共享该Executor中的那份变量副本。这样的话，可以大大减少变量副本的数量，从而减少网络传输的性能开销，并减少对Executor内存的占用开销，降低GC的频率。

广播大变量发送方式：Executor一开始并没有广播变量，而是task运行需要用到广播变量，会找executor的blockManager要，bloackManager找Driver里面的blockManagerMaster要。

使用广播变量可以大大降低集群中变量的副本数。不使用广播变量，变量的副本数和task数一致。使用广播变量变量的副本和Executor数一致。

7. **使用Kryo优化序列化性能**

在Spark中，主要有三个地方涉及到了序列化：

- 在算子函数中使用到外部变量时，该变量会被序列化后进行网络传输。
- 将自定义的类型作为RDD的泛型类型时（比如JavaRDD<ABC>，ABC是自定义类型），所有自定义类型对象，都会进行序列化。因此这种情况下，也要求自定义的类必须实现Serializable接口。
- 使用可序列化的持久化策略时（比如MEMORY\_ONLY\_SER），Spark会将RDD中的每个partition都序列化成一个大的字节数组。

Kryo序列化器介绍：Spark支持使用Kryo序列化机制。Kryo序列化机制，比默认的Java序列化机制，速度要快，序列化后的数据要更小，大概是Java序列化机制的1/10。所以Kryo序列化优化以后，可以让网络传输的数据变少；在集群中耗费的内存资源大大减少。

对于这三种出现序列化的地方，我们都可以通过使用Kryo序列化类库，来优化序列化和反序列化的性能。Spark默认使用的是Java的序列化机制，也就是ObjectOutputStream/ObjectInputStream API来进行序列化和反序列化。但是Spark同时支持使用Kryo序列化库，Kryo序列化类库的性能比Java序列化类库的性能要高很多。官方介绍，Kryo序列化机制比Java序列化机制，性能高10倍左右。Spark之所以默认没有使用Kryo作为序列化类库，是因为Kryo要求最好要注册所有需要进行序列化的自定义类型，因此对于开发者来说，这种方式比较麻烦。

Spark中使用Kryo：

|  |
| --- |
| Sparkconf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")  .registerKryoClasses(new Class[]{SpeedSortKey.class}) |

8. **优化数据结构**

java中有三种类型比较消耗内存：

1. 对象，每个Java对象都有对象头、引用等额外的信息，因此比较占用内存空间。
2. 字符串，每个字符串内部都有一个字符数组以及长度等额外信息。
3. 集合类型，比如HashMap、LinkedList等，因为集合类型内部通常会使用一些内部类来封装集合元素，比如Map.Entry。

因此Spark官方建议，在Spark编码实现中，特别是对于算子函数中的代码，尽量不要使用上述三种数据结构，尽量使用字符串替代对象，使用原始类型（比如Int、Long）替代字符串，使用数组替代集合类型，这样尽可能地减少内存占用，从而降低GC频率，提升性能。

## **shuffle优化**

参考shufffle优化参数部分。<https://mashibingmca.yuque.com/org-wiki-mashibingmca-ae2zgb/zr7gxl/kg8ro3bpmix0yepr>

## **SparkSQL优化**

参考SparkSQL优化部分。<https://mashibingmca.yuque.com/org-wiki-mashibingmca-ae2zgb/zr7gxl/ro107gm6terk1aig>
