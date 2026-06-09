## **Map Task运行**

JobSubmitter.submitJobInternal方法中最后提交Job如下：

|  |
| --- |
| ... ...  *//提交Job*status = submitClient.submitJob(  jobId, submitJobDir.toString(), job.getCredentials());  ... ... |

submitClient对象有两种实现：LocalJobRunner和YarnRunner，以LocalJobRunner为例，执行submitJob方法会创建Job对象并调用Job run方法运行map Task和Reduce Task。

LocaljobRunner.submitJob方法如下:

|  |
| --- |
| public org.apache.hadoop.mapreduce.JobStatus submitJob(  org.apache.hadoop.mapreduce.JobID jobid, String jobSubmitDir,  Credentials credentials) throws IOException {  *//new Job会执行start方法启动Job，进而调用Job中的run方法* Job job = new Job(JobID.*downgrade*(jobid), jobSubmitDir);  job.job.setCredentials(credentials);  return job.status;  } |

Job.run方法大体内容如下：

|  |
| --- |
| ... ...  *//根据切片组织 TaskSplitMetaInfo 对象*TaskSplitMetaInfo[] taskSplitMetaInfos =   SplitMetaInfoReader.*readSplitMetaInfo*(jobId, localFs, conf, systemJobDir);  *//获取ReduceTask个数*int numReduceTasks = job.getNumReduceTasks();  ... ...  *//组织MapTaskrunnable 后续提交执行*List<RunnableWithThrowable> mapRunnables = getMapTaskRunnables(  taskSplitMetaInfos, jobId, mapOutputFiles);  ... ...  *//运行map task*runTasks(mapRunnables, mapService, "map");  ... ...  *//运行reduce task*runTasks(reduceRunnables, reduceService, "reduce");  ... ... |

运行map task的runTasks方法中最终遍历mapTaskRunnable对象并执行run方法创建和运行mapTask。

mapTaskRunnable.run方法内容如下：

|  |
| --- |
| ... ...  *//创建MapTask*MapTask map = new MapTask(systemJobFile.toString(), mapId, taskId,  info.getSplitIndex(), 1);  ... ...  *//运行map task*map.run(localConf, Job.this);  ... ... |

最终mapTask运行会调用到MapTask.run方法，MapTask.run方法主要内容如下：

|  |
| --- |
| public void run(final JobConf job, final TaskUmbilicalProtocol umbilical)  throws IOException, ClassNotFoundException, InterruptedException {  ... ...  *//使用新API来执行map task*runNewMapper(job, splitMetaInfo, umbilical, reporter);  ... ...  } |

以上方法中使用新API来执行map task，MapTask.runNewMapper主要内容如下:

|  |
| --- |
| private <INKEY,INVALUE,OUTKEY,OUTVALUE>void runNewMapper(final JobConf job,  final TaskSplitIndex splitIndex,  final TaskUmbilicalProtocol umbilical,  TaskReporter reporter  ) throws IOException, ClassNotFoundException,  InterruptedException {  ... ...  *//获取用户的mapper类*org.apache.hadoop.mapreduce.Mapper<INKEY,INVALUE,OUTKEY,OUTVALUE> mapper =  (org.apache.hadoop.mapreduce.Mapper<INKEY,INVALUE,OUTKEY,OUTVALUE>)  ReflectionUtils.*newInstance*(taskContext.getMapperClass(), job);  *//获取用户指定的输入格式化类*org.apache.hadoop.mapreduce.InputFormat<INKEY,INVALUE> inputFormat =  (org.apache.hadoop.mapreduce.InputFormat<INKEY,INVALUE>)  ReflectionUtils.*newInstance*(taskContext.getInputFormatClass(), job);  *// 每个map task 构建自己对应的InputSplit分片*org.apache.hadoop.mapreduce.InputSplit split = null; split = getSplitDetails(new Path(splitIndex.getSplitLocation()),  splitIndex.getStartOffset());  *//根据当前map task的split、输入格式化类 信息创建 RecordReader对象* *//注意new NewTrackingRecordReader中 给RecordReader进行了赋值，默认为LineRecordReader*org.apache.hadoop.mapreduce.RecordReader<INKEY,INVALUE> input =  new NewTrackingRecordReader<INKEY,INVALUE>  (split, inputFormat, reporter, taskContext);  ... ...  *//设置每个split相对文件的偏移量起始位置* *//调用NewTrackingRecordReader.initialize方法*input.initialize(split, mapperContext);  *//运行Mapper类中的run方法*mapper.run(mapperContext);  ... ...  } |

在以上runNewMapper方法中，input.initialize(split, mapperContext) 方法最终调用到LineRecordReader.initialize方法，该方法中主要设置每个split相对文件的偏移量起始位置，每个split都会让出开头的一行，这样上一个split中最后可以读取到完整的一行数据。

LineRecordReader.initialize方法内容如下：

|  |
| --- |
| *//设置每个split对应文件上的偏移量起始位置*public void initialize(InputSplit genericSplit,  TaskAttemptContext context) throws IOException {  *//获取split起始位置*start = split.getStart();end = start + split.getLength();*//获取文件路径*final Path file = split.getPath();  ... ...  *//创建文件输入流对象：FSDataInputStream*fileIn = FutureIO.*awaitFuture*(builder.build());  ... ...  *//跳转到该split对应读取的开始位置上*fileIn.seek(start);  ... ...  *//如果该分片的start读取位置不为0，说明该split不是第一个split，从该split下一行开始的位置重新赋值给Start作为该split分片的开始位置。*  *//实际MR中除了最后一个spilt外，所有的split都会多读取一行数据，这样让出的数据被上个spilt进行了读取，让出的这一行会被数据移动到上个split中被处理* if (start != 0) {  start += in.readLine(new Text(), 0, maxBytesToConsume(start));  }  *//给pos赋值，该pos值后续用作每行数据相对文件偏移量的变量的开始位置* this.pos = start; } |

在以上runNewMapper方法中，mapper.run方法内容如下：

|  |
| --- |
| public void run(Context context) throws IOException, InterruptedException {  setup(context);  try {  *//context.nextKeyValue中在当前split分片中给每行数据的key和value进行赋值* while (context.nextKeyValue()) {  *//调用到自己实现的Mapper类中的map方法* map(context.getCurrentKey(), context.getCurrentValue(), context);  }  } finally {  cleanup(context);  } } |

其中while语句中的 context.nextKeyValue()方法调用的是LineRecoredReader.nextKeyValue()方法，可以看到在当前split中按照行进行每行读取数据，并除了最后一个split外都会往后多读取一行数据。map方法最终调用到用户自己编写的map数据处理逻辑。

LineRecoredReader.nextKeyValue()方法内容如下：

|  |
| --- |
| public boolean nextKeyValue() throws IOException {  ... ...  while (getFilePosition() <= end || in.needAdditionalRecordAfterSplit()) {  if (pos == 0) {  *//第一行跳过UTF-8文件开头的BOM（字节顺序标记），BOM是一个特殊的标记，用于标识文本文件所使用的Unicode编码格式*  *// UTF-8编码的BOM由三个字节 (0xEF, 0xBB, 0xBF) 组成。* newSize = skipUtfByteOrderMark();  } else {  *//后续读取都是以行为单位进行读取* newSize = in.readLine(value, maxLineLength, maxBytesToConsume(pos));  pos += newSize;  }  ... ...  } |

以上Map Task运行结论如下：

1. 默认数据输入是TextInputFormat，读取split数据时默认使用的LineRecorderReadr，即一行行读取数据。
2. 一行行读取数据时，除了最后一个split外，每个split都会在最后多读取一行数据。
3. 每个MapTask处理对应spilt数据时，会让出该split第一行数据，从下一行开始的位置作为该split的读取数据的start位置，MapRedcue中除了最后一个spilt外，所有的split都会多读取一行数据，这样下个Split让出的数据被上个spilt进行了读取，让出的这一行会被数据移动到上个split所在节点被处理。

## **Map Task输出**

在自己实现的Mapper类中，我们可以看到Map端最终将K,V格式数据通过“context.write(Key,Value);”写出,这里的context对象实际上就是WrappedMapper对象，所以write方法调用到WrappedMapper.write(...)方法。

WrappedMapper.write(...)方法如下：

|  |
| --- |
| public void write(KEYOUT key, VALUEOUT value) throws IOException,  InterruptedException {  mapContext.write(key, value); } |

以上代码中mapContext对象是在MapTask.runNewMapper(...)方法中创建的mapContext对象，MapTask.runNewMapper(...)方法关键代码如下:

|  |
| --- |
| *//将input 和 output 对象封装到mapContext对象中，后续mapper中使用context时可以获取到数据读取和写出的对象*org.apache.hadoop.mapreduce.MapContext<INKEY, INVALUE, OUTKEY, OUTVALUE>mapContext =   new MapContextImpl<INKEY, INVALUE, OUTKEY, OUTVALUE>(job, getTaskID(),   input, output,   committer,   reporter, split); org.apache.hadoop.mapreduce.Mapper<INKEY,INVALUE,OUTKEY,OUTVALUE>.Context   mapperContext =   new WrappedMapper<INKEY, INVALUE, OUTKEY, OUTVALUE>().getMapContext(  mapContext);  ... ... |

mapContext是MapContextImpl对象，其父类为TaskInputOutputContextImpl，所以mapContext.write(key, value);最终调用到TaskInputOutputContextImpl.write(...)实现。

TaskInputOutputContextImpl.write(...)代码如下：

|  |
| --- |
| public void write(KEYOUT key, VALUEOUT value  ) throws IOException, InterruptedException {  output.write(key, value); } |

以上代码中output对象是在MapTask.runNewMapper(...)方法中创建的NewOutputCollector对象，MapTask.runNewMapper(...)方法关键代码如下：

|  |
| --- |
| ... ...  *//准备 output 写出对象*if (job.getNumReduceTasks() == 0) { *//如果reduce task为0 ，即只有map端* output =   new NewDirectOutputCollector(taskContext, job, umbilical, reporter); } else {*//有map端也有reduce 端* output = new NewOutputCollector(taskContext, job, umbilical, reporter); }  ... ... |

所以，最终mapper端的写出就是调用的NewOutputCollector.write（...）方法，NewOutputCollector.write(...)具体代码如下：

|  |
| --- |
| *//Mapper 端context.write(...)写出数据时调用的就是MapTask中的write方法*@Overridepublic void write(K key, V value) throws IOException, InterruptedException {  *//传递给collector k,v,p，这里collector默认是MapOutputBuffer对象* collector.collect(key, value,  partitioner.getPartition(key, value, partitions)); } |

以上collector.collect(...)方法最终调用MapOutputBuffer.collect(...) 方法将数据结果写出到磁盘文件中去，完成map端数据写出磁盘文件。

在MapReduce中数据写入磁盘前会先写入环形缓冲区，默认100M大小，满80%会溢写磁盘，这些设置都是在执行“output = new NewOutputCollector(taskContext, job, umbilical, reporter);”中创建的，当创建 NewOutputCollector对象时创建了MapOutputCollector collect收集器对象并设置溢写时使用的分区器（默认为hashpartitioner）。创建NewOutputCollector对象时对应构造函数如下：

|  |
| --- |
| NewOutputCollector(org.apache.hadoop.mapreduce.JobContext jobContext,  JobConf job,  TaskUmbilicalProtocol umbilical,  TaskReporter reporter  ) throws IOException, ClassNotFoundException {  *//默认返回MapOutputBuffer对象, createSortingCollector中返回MapOutputBuffer对象，并设置数据溢写的分区、排序、combiner等操作* collector = createSortingCollector(job, reporter);   *//reduce task 个数赋值给partitions ，方便后续map端数据溢写进行分区* partitions = jobContext.getNumReduceTasks();  if (partitions > 1) {*//有多个分区，reduce task 有多个*  *//默认得到分区器是HashPartitioner，如果用户设置分区器，则使用用户设置的分区器* partitioner = (org.apache.hadoop.mapreduce.Partitioner<K,V>)  ReflectionUtils.*newInstance*(jobContext.getPartitionerClass(), job);  } else {*//只有1个分区，也就是只有1个reduce task* partitioner = new org.apache.hadoop.mapreduce.Partitioner<K,V>() {  @Override  public int getPartition(K key, V value, int numPartitions) {  return partitions - 1; *//直接返回的是0* }  };  } } |

createSortingCollector中返回MapOutputBuffer对象，并设置数据溢写的分区、排序、combiner等操作。MapTask.createSortingCollector方法大体逻辑如下：

|  |
| --- |
| private <KEY, VALUE> MapOutputCollector<KEY, VALUE>  createSortingCollector(JobConf job, TaskReporter reporter)  throws IOException, ClassNotFoundException {  *... ...*  *//默认返回的是MapOutputBuffer对象，该对象用于实现map端数据写出的逻辑*Class<?>[] collectorClasses = job.getClasses(  JobContext.*MAP\_OUTPUT\_COLLECTOR\_CLASS\_ATTR*, MapOutputBuffer.class);  *... ...*  *//collector默认为MapOutputBuffer对象*MapOutputCollector<KEY, VALUE> collector =  ReflectionUtils.*newInstance*(subclazz, job);*//初始化MapOutputCollector，这里涉及设置数据溢写的分区、排序、combiner等操作*collector.init(context);*LOG*.info("Map output collector class = " + collector.getClass().getName());*//返回的就是MapOutputBuffer对象*return collector; |

以上方法collector.init(context)中进行了环形缓冲区大小、溢写阈值、分区、排序、Combiner、守护线程溢写等设置。

MapOutputBuffer.init(Context)方法主要内容如下：

|  |
| --- |
| public void init(MapOutputCollector.Context context  ) throws IOException, ClassNotFoundException {  *... ...*  *//环形缓冲区80%溢写阈值*final float spillper =  job.getFloat(JobContext.*MAP\_SORT\_SPILL\_PERCENT*, (float)0.8);*//环形缓冲区默认大小为100M*final int sortmb = job.getInt(MRJobConfig.*IO\_SORT\_MB*,  MRJobConfig.*DEFAULT\_IO\_SORT\_MB*);  *... ...*  *//Map端排序器，默认为快速排序*sorter = ReflectionUtils.*newInstance*(job.getClass(  MRJobConfig.*MAP\_SORT\_CLASS*, QuickSort.class,  IndexedSorter.class), job);  *... ...*  *//排序使用的比较器，优先使用用户自定义比较器，否则使用当前key对象的默认比较器*comparator = job.getOutputKeyComparator();  *... ...*  *//map端Combiner*final Counters.Counter combineInputCounter =  reporter.getCounter(TaskCounter.*COMBINE\_INPUT\_RECORDS*);  *... ...*  *//数据溢写线程设置为守护线程*spillThread.setDaemon(true);  *... ...*  *//启动溢写线程*spillThread.start();  *... ...*  *}* |

spillThread.start()会检测溢写阈值达到80%时将环形缓冲区中的数据写出到磁盘。

最终多次溢写磁盘的多个小文件会在执行到MapTast.runNewMapper中的output.close()代码时进行合并成一个文件。

MapTask数据输出过程总结：

1. 当Redcue Task为1时，map端写出数据只有1个分区，不会经过分区、排序操作。
2. MapTask数据溢写时，默认分区器是HashPartitioner，如果用户设置分区器则使用用户分区实现类。
3. map数据写出缓冲区默认100M，80%会溢写。
4. 在溢写磁盘过程中会进行数据排序，优先获取用户自定义排序比较器，如果用户没有设置默认使用Key本身自带的比较器。
