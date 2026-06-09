1、解释一下什么是AQS（引出其他的JUC下的工具）

AQS的本质就JUC包下的一个抽象类

```java
package java.util.concurrent..;
public abstract class AbstractQueuedSynchronizer ...{
}
```

AQS就是一个基础类，并没有具体的并发功能实现，是JUC包下的大多数的工具都是基于AQS实现的，比如：ThreadPoolExecutor，ReentrantLock，CountDownLatch，Semaphore……

2、聊一下AQS中的三个核心内容

- state属性， **由volatile修饰，基于CAS修改** ，他是作为资源的int类型属性，比如CountDownLatch中他就是计数器中的内个数，ReentrantLock中他就是竞争锁修改的内个属性。。。。
- 同步队列（双向链表），拿不到资源的线程需要排队等，就在这个同步队列里等。**（类比EntryList）**
- 单向链表，一般是跟锁有关的，当持有锁的线程，执行了AQS提供的Condition里的await时，要扔到这个单向链表中挂起，等待被signal唤醒。**（类比WaitSet）**
