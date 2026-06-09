在开发中会用到的方式就是 **传递参数** 。

ThreadLocal有两个内存泄漏问题：

- **key：** key会在玩花活使用ThreadLocal时 ，在局部声明ThreadLocal，局部方法已经执行完毕，但是线程会指向ThreadLocalMap，ThreadLocalMap的key会指向ThreadLocal对象，这会导致ThreadLoc会被al对象不回收。所以ThreadLocal在设计时，将key的引用更改为了弱引用，如果再发生上述情况，此时ThreadLocal只有一个弱引用指向，可以被正常回收。
- **value：** 如果是普通线程使用ThreadLocal，那其实不remove也不存在问题，因为线程会结束，销毁，线程一销毁，就没有引用指向ThreadLocalMap了，自然可以回收。但是如果是线程池中的核心线程使用了ThreadLocal，那使用完毕，必须要remove，因为核心线程不会被销毁（默认），导致核心线程结束任务后，上一次的业务数据还遗留在内存中，导致内存泄漏问题。
