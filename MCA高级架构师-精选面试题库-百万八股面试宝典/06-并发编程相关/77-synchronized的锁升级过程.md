这个问题属于常识性问题，不深究特别底层的东西。

![](../assets/4ba18e3e96a6540d.png)

无锁：当前对象没有被作为锁资源存在 && 在JDK1.8中，会有一个4s的偏向锁延迟，这段时间的对象就处于无锁状态。

偏向锁：如果撇去4s的偏向锁延迟，那么刚new出来的对象，基本都是偏向锁。

Ps：如果某一个线程，反复的去获取同一把锁，此时偏向锁的优势就出现了，无需做CAS操作，比较一下指向的是否是当前线程，如果是，直接执行逻辑。

- 如果没有被所谓锁资源，那么这个偏向锁，没有偏向某一个线程。哪个线程都没偏向（匿名偏向）
- 作为锁资源存在了，同时指向着某一个线程，这个就是偏向锁（普通偏向）

轻量级锁：如果偏向锁状态下，出现了竞争，那么升级为轻量级锁。轻量级锁状态下，会执行多次CAS，默认初始次数是10次，这种CAS是采用的自适应自旋锁。

重量级锁：如果轻量级锁状态下，CAS完毕获取锁失败，直接升级到重量级锁。到了重量级锁的状态下，就是再次基于几次CAS尝试修改owner属性，成功，拿锁走人。 失败，挂起线程。等到其他线程释放锁后，再被唤醒。

**一般来说，锁只有升级，没有降级。**

**但是有点特殊情况，比如偏向锁可以退到无锁。因为偏向锁无法保存对象的hashcode，如果在偏向锁状态，并且没有作为锁的情况，执行了hashcode方法，会从偏向锁到无锁。、**

**下面是JIT优化导致的轻量级锁降级到无锁的状态**

```plain
public class LockTest {

    public static void main(String[] args) throws Exception  {
        synchronizedTest();

    }

    public static void synchronizedTest() throws InterruptedException {
        Thread.sleep(5000);
        Object o = new Object();
        // 00000101 无锁/匿名偏向
        System.out.println(ClassLayout.parseInstance(o).toPrintable());

        Thread thread = new Thread(() -> {
            synchronized (o) {
                // 10000010 重量级锁
                System.out.println(Thread.currentThread().getName() + "-1:" + ClassLayout.parseInstance(o).toPrintable());
            }

            // 00000010 重量级锁
            System.out.println(Thread.currentThread().getName() + "-2:" + ClassLayout.parseInstance(o).toPrintable());
            try {
                // 等待锁降级
                Thread.sleep(5000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // 00000001 无锁
            System.out.println(Thread.currentThread().getName() + "-3:" + ClassLayout.parseInstance(o).toPrintable());
            synchronized (o) {
                // 00010000 轻量级锁
                System.out.println(Thread.currentThread().getName() + "-4:" + ClassLayout.parseInstance(o).toPrintable());
            }

        });
        thread.start();

        synchronized (o) {
            // 00000101 无锁/匿名偏向
            System.out.println(Thread.currentThread().getName() + ":" + ClassLayout.parseInstance(o).toPrintable());
        }

        while (thread.isAlive()) {

        }
    }

}
```
