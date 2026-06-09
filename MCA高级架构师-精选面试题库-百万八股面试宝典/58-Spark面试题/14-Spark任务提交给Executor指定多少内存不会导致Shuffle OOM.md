实际情况中，Spark任务shuffle使用内存多少与处理数据量、并行度、执行业务逻辑、运行任务节点数各方面都有关系，假设现在限定场景，如果一个Spark任务输入数据为100G ，设置并行度为100，使用10个Executor执行，平均每个Executor分配10个Core（实际每个core运行2-3个task为宜），针对一个Executor使用内存计算如下：

## **Shuffle Map 端缓冲区大小**

Shuffle Write缓冲区的大小可以通过以下公式来计算：

|  |
| --- |
| Shuffle Write缓冲区大小 = 并行度 \* spark.shuffle.spill.diskWriteBufferSize |

其中，executor中task为10，spark.shuffle.spill.diskWriteBufferSize 设置Map端数据记录排序后写入磁盘文件时使用的缓冲区大小，默认值为1M。因此，Shuffle Write缓冲区大小可以计算为：Shuffle Write缓冲区大小 = 10 \* 1MB = 10M。

## **计算Reduce端的Shuffle Read缓冲区大小**

Shuffle Read 缓冲区的大小可以通过以下公式来计算：

|  |
| --- |
| Shuffle Read 缓冲区大小 = 并行度 \* spark.reducer.maxSizeInFlight |

其中，每个Executor并行度为10，spark.reducer.maxSizeInFlight为Shuffle 为拉取数据缓冲区大小，默认值为48MB。因此，Shuffle Write缓冲区大小可以计算为：Shuffle Read缓冲区大小 = 10 \* 48MB = 480M。

## **计算每个Executor总内存大小**

按照以上并行度，每个Executor中平均分配10个task，也就是每个Executor中shuffle 使用内存缓冲约为480M+10M = 490M ，每个Executor总内存大小可以通过以下公式来计算(按照统一内存管理计算):

|  |
| --- |
| Shuffle缓冲内存 = [Executor总内存大小 - 300M(Executor的保留内存大小)] \*spark.memory.fraction \* 50% |

其中spark.memory.fraction 为 0.6 ，经计算Executor总内存大小约为2G 。Executor默认分配内存大小为spark.executor.memoryOverhead，默认值为1GB，可以根据具体计算值来决定要不要提高Executor内存大小。

此外，Executor中task 处理业务逻辑如果复杂、对象多，有可能给定的Executor内存分配给task计算内存不足（（总-300）\*0.25），或者有可能业务涉及RDD缓冲和广播变量（spark.memory.storageFraction），也有可能给定的Executor内存按照这个比例不够导致Executor内存不足，这里需要具体情况具体分析。建议观察任务历史数据，例如：在Spark任务运行时，可以通过Spark UI或者YARN等资源管理器的Web UI查看任务的历史数据，包括Shuffle阶段的内存使用情况、磁盘写入情况等等。根据历史数据来估算合适的内存大小。
