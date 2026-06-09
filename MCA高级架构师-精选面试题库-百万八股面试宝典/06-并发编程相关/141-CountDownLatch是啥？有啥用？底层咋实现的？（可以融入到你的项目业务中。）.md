CountDownLatch本质其实就是一个计数器。

在多线程并形处理业务时，需要等待其他线程处理完，再做后续的合并等操作，再响应用户时，可以使用CountDownLatch做计数，等到其他线程出现完之后，主线程就会被唤醒。

CountDownLatch本身就是基于AQS实现的。

new CountDownLatch时，直接指定好具体的数值。这个数值会复制给state属性。

当子线程处理完任务后，执行countDown方法，内部就是直接给state - 1而已。

当state减为0之后，执行await挂起的线程，就会被唤醒。

CountDownLatch不能重复使用，用完就凉凉。
