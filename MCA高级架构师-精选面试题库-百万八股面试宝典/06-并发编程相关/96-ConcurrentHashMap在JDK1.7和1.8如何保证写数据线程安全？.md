![](../assets/c744aa7c0525c32b.png)

JDK1.7里的锁，一般称为Segement，是基于ReentrantLock实现的。

JDK1.8里，用了两种锁，如果数据要写入到数组上，基于CAS的方式尝试写入。如果数据要挂到链表或者红黑树上时，采用synchronized锁住数组上的Node。
