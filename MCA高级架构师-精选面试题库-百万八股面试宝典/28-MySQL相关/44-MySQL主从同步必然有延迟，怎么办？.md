只能尽量的减少延迟，想解决的话，同步的成本很高。

如果必须要数据强一致，那就不能用主从的效果，自己搞一个众生平等的套路。

让写数据的时，同步写到多个MySQL节点中，都成功才成功！但是这样，写操作的效率必然大打折扣！（基本没有这么干的）

但是一般情况下，大多是尽可能的提升主从同步的效率。。。

- 优化查询等其他操作，让出服务器资源，避免影响同步时的资源被占用…………
- 规避大事务，别一次同步大量数据，这个成本也高…………
- MySQL从库同步时，可以指定多线程同步，提升效率：<https://dev.mysql.com/doc/refman/8.0/en/replication-options-replica.html#sysvar_replica_parallel_workers> （搜workers）
- bin log同步可以指定具体的库，减少不必要的同步操作。<https://dev.mysql.com/doc/refman/8.0/en/replication-options-replica.html#--replicate-do-db> （搜do-db）
- 服务器的资源给力点，网络的带宽大一点，磁盘必然上固态，多多监控一下，如果有延迟时间长的点，排查一下………………
- 半同步复制的套路………………
