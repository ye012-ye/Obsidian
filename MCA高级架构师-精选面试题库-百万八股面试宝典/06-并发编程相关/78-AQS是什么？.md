AQS本质就是个抽象类，AbstractQueuedSynchronizer。AQS是JUC包下的一个基础类，没有具体的并发功能的实现，不过大多数JUC包下的工具都或多或少继承了AQS去做具体的实现。

比如ReentrantReadWriteLock，ReentrantLock，CountDownLatch，线程池之类的，都用继承了AQS做自己的实现。

AQS有三个核心点：

- volatile修饰int属性state。（如果作为锁，state == 0，代表没有线程持有锁资源，如果大于0，代表有线程持有锁资源）
- 基于Node对象组成的一个同步队列（如果线程想获取lock锁，结果失败了，会被挂起线程，线程会被封装为Node对象，扔到这个同步队列中）
- 基于Node对象组成的单向链表（当线程持有锁资源时，如果执行了await，线程会释放锁资源，并且将线程封装为Node对象，扔到这个单向链表中。如果其他线程执行了signal，那就会将单向链表的Node节点扔到同步队列）
