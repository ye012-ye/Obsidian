这几个方法都是ReentrantLock获取锁的方法。。。。

lock：拿不到锁直接排队，即便排队时期被中断了（interrupt），依然会继续排队，死等，拿不到锁，就不走了！等到拿道锁，确认是否被中断过，如果中断过，就保留中断标记位。

tryLock()：浅尝一下，就抢一次，抢到拿锁走人返回true，抢不到，返回false

tryLock(timeout,unit)：浅尝timeout.unit时间，最多等待timeout.unit时间，拿到锁返回true，反之false。并且在等待过程中，如果被中断，会抛出InterruptedException。

lockInterruptibly：拿不到锁直接排队，要么拿锁走人，要么被中断抛出InterruptedException。
