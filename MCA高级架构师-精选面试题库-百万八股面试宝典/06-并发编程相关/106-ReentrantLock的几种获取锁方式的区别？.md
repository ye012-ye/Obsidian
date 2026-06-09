- lock
- tryLock()
- tryLock(time,unit)
- lockInterruptibly

lock方法：死等，如果那不到锁，就一直等，你interrupt中断了也一直等。

tryLock()方法：浅尝一下，试一下，就一下，拿到快乐的返回true，拿不到，返回false。

tryLock(time,unit)方法：尝试time.unit这么尝试时间，如果拿到了，返回true，时间到了，没拿到，返回false。如果在拿的过程中，线程中断了，就抛出异常。

lockInterruptibly方法：死等，如果那不到锁，就一直等，如果被interrupt中断了，抛出异常
