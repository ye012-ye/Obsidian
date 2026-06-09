MapReduce中Reduce端拉取Map端数据后，会对key进行分组处理，这部分源码主要来看MapRedcue Reduce端如何针对一组key将对应的value进行获取。

MapReduce Job运行后，Job的run方法中执行完成map task后会执行reduce task，代码如下：

|  |
| --- |
| public void run() {  ... ...  *//运行map task，实际调用到每个mapTaskRunnable 的run方法*runTasks(mapRunnables, mapService, "map");  ... ...  *//运行reduce task*if (numReduceTasks > 0) {  List<RunnableWithThrowable> reduceRunnables = getReduceTaskRunnables(  jobId, mapOutputFiles);  ExecutorService reduceService = createReduceExecutor();  *//运行reduce task* runTasks(reduceRunnables, reduceService, "reduce");  .... ...  } |

与Map Task运行一样，“runTasks(reduceRunnables, reduceService, "reduce");”最终会遍历RunnableWithThrowable对象进行执行对应run方法，RunnableWithThrowable的实现类是ReduceTaskRunnable，所以最终调用到ReduceTaskRunnable.run方法，在该方法中会创建Redcue Task并运行。

ReduceTaskRunnable.run方法大体逻辑如下：

|  |
| --- |
| *//reduce task运行调用方法*public void run() {  *//创建ReduceTask*ReduceTask reduce = new ReduceTask(systemJobFile.toString(),  reduceId, taskId, mapIds.size(), 1);  ... ...  *//运行 reduce task*reduce.run(localConf, Job.this);  ... ...  } |

以上reduce.run执行的是ReduceTask.run方法，该方法中会将Map端shuffle数据copy到reduce端组织成RawKeyValueIterator对象，对应的变量为rIter，然后Reduce端会使用新API遍历该迭代器中的数据按照用户传入的逻辑进行处理。

ReduceTask.run方法重点逻辑如下：

|  |
| --- |
| public void run(JobConf job, final TaskUmbilicalProtocol umbilical)  ... ...  *//shuffle拉取数据，将map端数据拉取到Reduce端经过归并形成迭代器*rIter = shuffleConsumerPlugin.run();  ... ...  *//使用新API运行reduce task，这里传入了rIter 迭代器数据*runNewReducer(job, umbilical, reporter, rIter, comparator,   keyClass, valueClass);  ... ...  } |

ReduceTasK.runNewReducer重点逻辑如下:

|  |
| --- |
| private <INKEY,INVALUE,OUTKEY,OUTVALUE>void runNewReducer(JobConf job,  final TaskUmbilicalProtocol umbilical,  final TaskReporter reporter,  RawKeyValueIterator rIter,  RawComparator<INKEY> comparator,  Class<INKEY> keyClass,  Class<INVALUE> valueClass  ) throws IOException,InterruptedException,   ClassNotFoundException {  ... ...  *//用户自定义实现的reducer 类*org.apache.hadoop.mapreduce.Reducer<INKEY,INVALUE,OUTKEY,OUTVALUE> reducer =  (org.apache.hadoop.mapreduce.Reducer<INKEY,INVALUE,OUTKEY,OUTVALUE>)  ReflectionUtils.*newInstance*(taskContext.getReducerClass(), job);  ... ...  *//创建reducerContext对象，即：WrappedReducer 对象，其中在创建ReduceContextImpl时，将rIter赋值给input*org.apache.hadoop.mapreduce.Reducer.Context   reducerContext = *createReduceContext*(reducer, job, getTaskID(),  rIter, reduceInputKeyCounter,   reduceInputValueCounter,   trackedRW,  committer,  reporter, comparator, keyClass,  valueClass);  ... ...  *//传入的reduceContext对象是 WrappedReducer*reducer.run(reducerContext);  ... ...  } |

最终redcue.run方法调用到Redcuer.run方法，逻辑如下：

|  |
| --- |
| public void run(Context context) throws IOException, InterruptedException {  setup(context);  try {  *//context.nextKey() 中context对象是 WrappedReducer*  *//context.nextKey() 这里进行从map端获取迭代器数据第一条数据key,value的获取，以及判断下个key和当期处理key是否相同* while (context.nextKey()) {  *//这里reduce 方法执行就是用户自定义实现的reducer类中的方法* reduce(context.getCurrentKey(), context.getValues(), context);  *// If a back up store is used, reset it* Iterator<VALUEIN> iter = context.getValues().iterator();  if(iter instanceof ReduceContext.ValueIterator) {  ((ReduceContext.ValueIterator<VALUEIN>)iter).resetBackupStore();   }  }  } finally {  cleanup(context);  } } |

以上逻辑中通过while (context.nextKey())来判断Reduce Task是否有处理数据，并最终调用到reduce(context.getCurrentKey(), context.getValues(), context);方法执行到用户定义的redcue逻辑。

以上处理过程中有两个重点，一个是Redcue task处理的数据可能有很多组，每组如何区分？另外一个就是每组的value值如何获取到的？

在while (context.nextKey())判断是否存在下一条数据中，context.nextKey()实际调用的是ReduceContextImpl.nextKey()方法，大体逻辑如下：

|  |
| --- |
| public boolean nextKey() throws IOException,InterruptedException {  *//如果有数据，并且下条数据key与当前处理key相同，则获取下条数据，nextKeyIsSame 首次运行为false* while (hasMore && nextKeyIsSame) {  *//获取下个k,v* nextKeyValue();  }  *//源头迭代器有数据* if (hasMore) {  if (inputKeyCounter != null) {  inputKeyCounter.increment(1);  }  *//最终返回的true,但在nextKeyValue方法中 进行了key value 数据的反序列化，方便后续获取到* return nextKeyValue();  } else {  return false;  } } |

以上逻辑重点方法为 nextKeyValue()，该方法最终返回true，同时在该方法中还进行了key ，value数据的反序列化操作、判断当前处理的key是否和下一条从迭代器中获取的数据key是否相同，如果相同表示下一条数据是当前组数据，否则表示当前组数据已经处理完，nextKeyValue()逻辑如下：

|  |
| --- |
| public boolean nextKeyValue() throws IOException, InterruptedException {  ... ...  *//第一次运行 firstValue为true ,因为默认nextKeyIsSame 为false*firstValue = !nextKeyIsSame;*//从迭代器中获取从map端获取key值*DataInputBuffer nextKey = input.getKey();  ... ...  key = keyDeserializer.deserialize(key);*//从迭代器中获取从map端获取value值*DataInputBuffer nextVal = input.getValue();  ... ...  *//反序列化value*value = valueDeserializer.deserialize(value);  ... ...  *//hasMore判断是否还有下一条*hasMore = input.next();  if (hasMore) {  *//如果有下一条数据，获取对应的key* nextKey = input.getKey();  *//然后检查获取的key是否和当前处理的 key 一样* nextKeyIsSame = comparator.compare(currentRawKey.getBytes(), 0,   currentRawKey.getLength(),  nextKey.getData(),  nextKey.getPosition(),  nextKey.getLength() - nextKey.getPosition()  ) == 0; } else {  nextKeyIsSame = false; }  ... ....  return true; } |

在reduce(context.getCurrentKey(), context.getValues(), context);代码中context.getValues()实际调用的是RedcueContextImpl.getValue()方法，该方法返回一个ValueIterable对象：

|  |
| --- |
| public Iterable<VALUEIN> getValues() throws IOException, InterruptedException {  return iterable; } |

iterable即ValueIterable，ValueIterable对象实现了Iterable接口，如下：

|  |
| --- |
| *//用户获取key对应values 返回的就是 ValueIterable 对象*protected class ValueIterable implements Iterable<VALUEIN> {  private ValueIterator iterator = new ValueIterator();  @Override  public Iterator<VALUEIN> iterator() {  return iterator;  }  } |

可以看到当用户对相同的key的values调用iterator时，实际上调用到的就是ValueIterable.iterator方法，这里返回的是一个ValueIterator迭代器对象，当用户代码中执行iter.hasNext和iter.next()时，实际上调用的是ValueIterator.hasNext方法和ValueIterator.next()方法，在ValueIterator.next()方法中可以看到最终调用到nextKeyValue()方法，从map端拉取过来落地磁盘形成的迭代器中获取一个个value值，并非将当前key所有的value值一次性获取到Reduce端内存中。ValueIterator.next()具体代码如下：

|  |
| --- |
| public VALUEIN next() {  ... ...  *//如果是第一条数据直接返回第一条数据*if (firstValue) {  firstValue = false;  return value; }  .... ...  *//调用nextKeyValue 方法获取当前组中下一条数据，并返回*  nextKeyValue();return value;  } |

在Redcue中将每个key及对应的values获取到后传给用户自定义的逻辑进行处理，最终写出到磁盘文件中。

ReduceTask源码总结：

1. Reduce 端从Map端获取数据后，会经过归并排序将数据形成一个迭代器RawKeyValueIterator，这样后续可以直接从迭代器中遍历每条数据使用。
2. Reduce 处理每组key对应的value值时，并非将当前key所有的value值存入reduce端的内存中，而是创建了一个ValueIterator迭代器最终从RawKeyValueIterator迭代器中获取每个value值，这样设计的好处是每个ReduceTask只需要遍历一遍磁盘数据就可以将每组key对应的所有value值都能获取到。
