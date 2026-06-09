SparkShuffle参数设置可以通过三种方式:

1. 在代码中设置，硬编码不建议

|  |
| --- |
| val conf = new SparkConf()  conf.set(“spark.reducer.maxSizeInFlight”,100) |

2. 提交Spark任务时设置，推荐使用
3. 在$SPARK\_HOME/conf/spark-default.conf配置，不建议，因为所有任务都会使用该参数。

关于Spark shuffle优化的参数如下：

- **spark.reducer.maxSizeInFlight**

**参数说明**：该参数用于设置shuffle read task的buffer缓冲大小，而这个buffer缓冲决定了每次能够拉取多少数据，默认48M。

**调优建议：**如果作业可用的内存资源较为充足的话，可以适当增加这个参数的大小（比如96m），从而减少拉取数据的次数，也就可以减少网络传输的次数，进而提升性能。在实践中发现，合理调节该参数，性能会有1%~5%的提升。

- **spark.shuffle.compress和 spark.shuffle.spill.compress**

**参数说明：**spark.shuffle.compress和spark.shuffle.spill.compress都是用来设置Shuffle过程中是否对Shuffle数据进行压缩，**两者默认值都为true**。其中前者针对最终写入本地文件系统的输出文件，后者针对在处理过程需要spill到外部存储的中间数据，后者针对最终的shuffle输出文件。

**调优建议：**对于参数spark.shuffle.compress，如果下游的Task通过网络获取上游Shuffle Map Task的结果的网络IO成为瓶颈，那么就需要考虑将它设置为true,通过压缩数据来减少网络IO。由于上游Shuffle Map Task和下游的Task现阶段是不会并行处理的，即上游Shuffle Map Task处理完成，然后下游的Task才会开始执行,因此如果需要压缩的时间消耗就是Shuffle MapTask压缩数据的时间 + 网络传输的时间 + 下游Task解压的时间,而不需要压缩的时间消耗仅仅是网络传输的时间,因此需要评估压缩解压时间带来的时间消耗和因为数据压缩带来的时间节省。**如果网络成为瓶颈，比如集群普遍使用的是千兆网络，那么可能将这个选项设置为true是合理的**；**如果计算是CPU密集型的，那么可能将这个选项设置为false才更好。**

- **spark.shuffle.spill.diskWriteBufferSize**

**参数说明**：该参数设置Map端数据**记录排序后**写入磁盘文件时使用的缓冲区大小，默认值为1024\*1024字节，也就是1M。

**调优建议：**在Spark任务需要大量Shuffle情况下，如果内存充足可以适当提高该参数值，减少写入磁盘的次数，提高Shuffle性能。

- **spark.shuffle.file.buffer：**

**参数说明**：该参数用于设置shuffle write task的BufferedOutputStream的buffer缓冲大小（默认是32K）。将数据写到磁盘文件之前，会先写入buffer缓冲中，待缓冲写满之后，才会溢写到磁盘。

**调优建议**：如果作业可用的内存资源较为充足的话，可以适当增加这个参数的大小（比如64k），从而减少shuffle write过程中溢写磁盘文件的次数，也就可以减少磁盘IO次数，进而提升性能。在实践中发现，合理调节该参数，性能会有1%~5%的提升。

- **spark.shuffle.io.maxRetries**

**参数说明**：Shuffle Read Task从Shuffle Write Task 所在节点拉取属于自己的数据时，因网络异常导致拉取失败，是会自动进行重试，改参数是自动重试次数，默认3次。如果在指定的次数内拉取还是没有成功，就可能导致作业执行失败。

**调优建议**：对于那些包含了特别耗时的Shuffle操作时，建议增加最大的重试次数，以避免由于JVM的Full GC或者网络不稳定等因素导致的数据拉取失败。对于超大的数据量时可以提升集群的稳定性。

- **spark.shuffle.io.retryWait**

**参数说明**：具体解释同上，该参数代表了每次重试拉取数据的等待间隔，默认是5s。由于网络之间不稳定导致数据拉取最大的延迟为 spark.shuffle.io.maxRetries\*spark.shuffle.io.retryWait =3\*5 = 15s。

**调优建议**：建议加大间隔时长（比如60s），以增加shuffle操作的稳定性。

- **spark.shuffle.io.numConnectionsPerPeer**

**参数说明**：Spark集群节点之间会创建获取数据的并发连接数，该参数配置可以重新使用主机之间的连接，默认为1，对于具有多个硬盘和少量主机的集群，这可能导致并发性不足，可以将该值设置大一些，以使所有磁盘饱和。

**调优建议**：机器之间的可以重用的网络连接，主要用于在大型集群中减小网络连接的建立开销，如果一个集群的机器并不多，可以考虑增加这个值。

- **spark.network.timeout/spark.shuffle.io.connectionTimeout**

**参数说明**:spark.network.timeout:Spark所有网络之间交互的超时时间，默认120s。spark.shuffle.io.connectionTimeout :节点之间有连接，但是通道没有数据，连接的超时时间，此值默认与spark.network.timeout一样，默认为120s。

**调优建议**：如果节点负载较高，建议将该值调大，以减少由于节点负载高导致通信或传输中断的情况发生。

- **spark.shuffle.sort.bypassMergeThreshold**

**参数说明**：当ShuffleManager为SortShuffleManager时，如果shuffle task的数量小于这个阈值（默认是200），则shuffle write过程中不会进行排序操作，而是直接将数据写入到磁盘临时文件，但是最后会将每个task产生的所有临时磁盘文件都合并成一个文件，并会创建单独的索引文件。

**调优建议：**当你使用SortShuffleManager时，如果的确不需要排序操作，那么建议将这个参数调大一些，大于shuffle task的数量。那么此时就会自动启用bypass机制，map-side就不会进行排序了，减少了排序的性能开销。

- **spark.shuffle.mapOutput.minSizeForBroadcast**

**参数说明**：Spark作业中是否应该对较小的map输出进行广播。如果一个任务的map输出小于这个阈值，则该输出将被广播到所有reduce任务中，而不是通过网络进行shuffle传输。默认512K。

**调优建议**：如果你处理的数据中存在一些常用的小数据需要shuffle，比如字典表或者一些常量等，那么将该值调大可能会带来更好的性能，因为此时这些小数据可以被广播到所有的 reduce 任务，避免重复的计算和传输，可以尝试调大该值。

- **spark.shuffle.service.enabled**

**参数说明**：是否启用External shuffle Service服务，默认false。Spark系统在运行含shuffle过程的应用时，Executor进程除了运行task，还要负责写shuffle数据，给其他Executor提供shuffle数据。当Executor进程任务过重，导致GC而不能为其他Executor提供shuffle数据时，会影响任务运行。External shuffle Service是长期存在于NodeManager进程中的一个辅助服务。通过该服务来抓取shuffle数据，减少了Executor的压力，在Executor GC的时候也不会影响其他Executor的任务运行

**优化建议**：启用外部shuffle服务，这个服务会安全地保存shuffle过程executor写的磁盘文件，因此executor即使挂掉也不要紧，必须配合spark.dynamicAllocation.enabled属性设置为true，才能生效，而且外部shuffle服务必须进行安装和启动，才能启用这个属性。
