知道，回答完毕。

**传参。** 你可以和上面聊策略 + 责任链的设计模式结合在一起。

聊一下具体的项目中哪个业务涉及到了。

**ThreadLocal存储数据的方式。**

ThreadLocal本身不存储数据，他只是一个key。

真正存储数据的，是线程对象Thread当中的一个Map。

这个Map的底层是一个Entry数组，每一个Entry都可以存储key和value。

其中的key，就是ThreadLocal。

可以声明多个ThreadLocal对象，但是存储数据的，就是线程中的内个Entry数组。

**内存泄漏问题。**

ThreadLocal有两个内存泄漏问题

key的内存泄漏，这个问题已经被解决了，因为ThreadLocal内部对Key的引用是弱引用。

value的内存泄漏问题，在线程池操作ThreadLocal时，因为线程一致没有被回收，Entry数组他就一直在，前面如果ThreadLocal被回收掉了，但是value还在，导致value占用内存，但是你还查询不到。还有一个安全问题，上次逻辑存储的数据，在下次逻辑里又查询出来了。所以value的内存泄漏问题，需要咱们在使用完毕后，主动的remove，避免下次操作出现问题。
