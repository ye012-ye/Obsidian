sc.textFile(“hdfs://mycluster/xx.txt”).flatMap(\_.split(“,”)).map((\_,1)).reduceByKey(\_+\_).collect()
