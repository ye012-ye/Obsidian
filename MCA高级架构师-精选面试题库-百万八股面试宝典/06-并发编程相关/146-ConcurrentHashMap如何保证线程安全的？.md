回答1：尾插，其次扩容有CAS保证线程安全

回答2：写入数组时，基于CAS保证安全，挂入链表或插入红黑树时，基于synchronized保证安全。

回答3：这里ConcurrentHashMap是采用LongAdder实现的技术，底层还是CAS。（AtomicLong）

回答4：ConcurrentHashMap扩容时，一点基于CAS保证数据迁移不出现并发问题， 其次ConcurrentHashMap还提供了并发扩容的操作。举个例子，数组长度64扩容为128，两个线程同时扩容的话，

线程A领取64-48索引的数据迁移任务，线程B领取47-32的索引数据迁移任务。关键是领取任务时，是基于CAS保证线程安全的。
