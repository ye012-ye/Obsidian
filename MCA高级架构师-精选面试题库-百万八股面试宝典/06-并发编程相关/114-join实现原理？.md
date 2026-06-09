比如主线程执行t1.join()，主线程需要等待t1执行完之后，再执行。

主线程挂起了一会，等到t1执行完了，主线程被唤醒？

答：Join方法本质是基于synchronized以及wait和notify实现的。直接针对当前线程对象加锁，然后wait挂起线程，wait判断的逻辑是t1线程是否存活。isAlive。如果t1线程存货，WAITING这，如果t1线程凉凉了，isAlive会返回false，不用挂起了，被唤醒。
