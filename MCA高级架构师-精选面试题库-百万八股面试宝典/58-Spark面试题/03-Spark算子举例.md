## **Transformation算子：**

filter,map,flatMap,sample,reduceByKey,sortByKey,sortBy,join,leftOuterJoin,rightOuterJoin,fllOuterJoin,union,interserction,subtract,distinct,cogroup,mapPartitionWithIndex,repartition,coalesce(boolean),groupByKey,zip,zipWithIndex,mapValues,aggreagteByKey,combainerByKey

## **Action算子：**

count,take(num),first,foreach,collect,foreachPartition,takeSample(boolean,num,seed),saveAsTextFile,collectAsMap,top(num),takeOrderd(num),reduce,countByKey,countByValue

## **控制算子：**

控制算子有三种，cache,persist,checkpoint，以上算子都可以将RDD持久化，持久化的单位是partition。cache和persist都是懒执行的。必须有一个action类算子触发执行。checkpoint算子不仅能将RDD持久化到磁盘，还能切断RDD之间的依赖关系。

**cache：**默认将RDD的数据持久化到内存中。cache是懒执行。

**persist：**可以指定持久化的级别。最常用的是MEMORY\_ONLY和MEMORY\_AND\_DISK。

**checkpoint：**可以将RDD持久化到磁盘，还可以切断RDD之间的依赖关系。checkpoint目录数据当application执行完之后不会被清除，可以用于状态管理。对RDD执行checkpoint之前，最好对这个RDD先执行cache，这样新启动的job只需要将内存中的数据拷贝到HDFS上就可以，省去了重新计算这一步。

以上三种持久化算子注意点如下:

1. cache和persist都是懒执行，必须有一个action类算子触发执行。
2. cache和persist算子的返回值可以赋值给一个变量，在其他job中直接使用这个变量就是使用持久化的数据了。持久化的单位是partition。
3. cache和persist算子后不能立即紧跟action算子，否则返回一个数值，也没有使用持久化。
4. cache和persist算子持久化的数据当applilcation执行完成之后会被清除。
5. checkpoint需要指定额外的目录存储数据，checkpoint数据是由外部的存储系统管理，不是Spark框架管理，当application完成之后，不会被清空。cache() 和persist() 持久化的数据是由Spark框架管理，当application完成之后，会被清空。
