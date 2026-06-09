## **Map Task设置**

MapReduce中，Map Task的数量由输入数据的Split分片数量决定，每个Split对应一个Map Task，每个split大小默认和blockSize大小一样，为128M。

如果不想按照默认这种方式进行split分片，可以调节mapreduce.input.fileinputformat.split.minsize或者mapreduce.input.fileinputformat.split.maxsize参数，假设想要调节Split大小为100M，那么就设置mapreduce.input.fileinputformat.split.maxsize为100M即可，如果要调节Split为200M，那么就设置mapreduce.input.fileinputformat.split.minsize为200M即可。调节了Split分片大小实际上也就是调节了Map Task数量。以上参数设置方式如下：

|  |
| --- |
| *// 创建配置及job对象*Configuration conf = new Configuration();*// 设置分片最小大小为256MB*conf.setLong("mapreduce.input.fileinputformat.split.minsize", 256 \* 1024 \* 1024L); |

此外，如果MapReduce中Map端读取的是大量小文件，每个小文件对应一个Map Task。

## **Reduce Task设置**

MapReduce中，如果代码中没有指定Reduce Task个数，那么默认Reduce Task个数为1，最终结果数据会写入到一个文件中。可以通过如下方式在Driver端设置Reduce Task个数，这样 MapReduce结果将根据多个Reduce Task写入多个文件。

|  |
| --- |
| *//设置MapReduce Reduce Task个数*job.setNumReduceTasks(2); |

设置多个Reduce Task后，每个Reduce Task处理的数据会按照默认的HashPartitioner 方式决定。
