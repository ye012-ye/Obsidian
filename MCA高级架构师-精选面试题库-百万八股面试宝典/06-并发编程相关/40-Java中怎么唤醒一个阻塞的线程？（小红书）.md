唤醒线程的方式：

- interrupt……
- Unsafe.unpark……

首先，线程阻塞的方式，在Java中其实只有一种形式，就是Unsafe类中的park方法去挂起的。

只不过Java中针对这种阻塞的状态，细分了3种：

- BLOCKED：synchronized…………
- WAITING
- TIMED\_WAITING

这三个状态，其实对于操作系统来说，没区别，Java中细分的目的是为了让咱们在排查问题时，可以更好的定位。

**Java线程在获取synchronized锁资源失败后，如果该线程执行了interrupt，那这个线程会被唤醒吗？**

答：synchronized加锁的核心逻辑都是在C++内部实现的，如果在基于synchronized挂起后，线程被执行了 **interrupt** ，在C++的代码中，会被唤醒，并且可以执行CAS尝试获取锁资源，但是一般情况下，拿不到就再次被挂起了。而在Java中能看到的效果就是，没有任何效果（没拿到锁）。

其他的类似WAITING和TIMED\_WAITING必然也是可以唤醒的，只是根据后续工具的代码逻辑来决定是否能真正的唤醒到自己编写的业务代码中。

比如lock.lock方法，synchronized的阻塞形式，中断后不一定会回到你自己的业务代码中。

但是比如lock.lockInterruptibly，Thread.sleep()，等可以在中断后，抛出interrupt异常能看到效果。
