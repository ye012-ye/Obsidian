synchronized应该不陌生，这东西就是JVM层面最原始的互斥锁。

使用方式，就同步代码块，同步方法。

**这个是重量级锁的原理。**

synchronized因为是互斥锁，只能有一个线程持有当前锁资源。所以synchronized底层有一个owner属性，这个属性是当前持有锁的线程。如果owner是NULL，其他线程就可以基于CAS将owner从NULL修改为当前线程，只要这个CAS动作成功了，就可以获取这个synchronized锁资源。如果失败了，会再尝试几次CAS，没拿到就park挂起当前线程。
