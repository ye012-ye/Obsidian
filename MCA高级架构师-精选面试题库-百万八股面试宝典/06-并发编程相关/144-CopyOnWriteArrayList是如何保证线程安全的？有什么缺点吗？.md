CopyOnWriteArrayList写数据时，是基于ReentrantLock保证原子性的。

其次，写数据时，会复制一个副本写入，写入成功后，才会写入到CopyOnWriteArrayList中的数组。

保证读数据时，不要出现数据不一致的问题。

如果数据量比较大时，每次写入数据，都需要复制一个副本，对空间的占用太大了。如果数据量比较大，不推荐使用CopyOnWriteArrayList。

**写操作要求保证原子性，读操作保证并发，并且数据量不大 ~**
