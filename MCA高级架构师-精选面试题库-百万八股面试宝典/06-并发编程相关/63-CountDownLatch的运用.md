CountDownLatch就是一个计数器。这个计数器是你指定好数值，比如你指定3，每次执行countDown就-1，见到0之后，任务处理完毕。

```java
@SneakyThrows
public static void findBy三方(){Thread.sleep(700);}
@SneakyThrows
public static void findByMySQL(){Thread.sleep(200);}
@SneakyThrows
public static void findByB服务(){Thread.sleep(300);}

public static void main(String[] args) {
    ExecutorService executor = Executors.newFixedThreadPool(3);
    CountDownLatch count = new CountDownLatch(3);
    executor.execute(() -> {
        findBy三方();
        count.countDown();
    });
    executor.execute(() -> {
        findByMySQL();
        count.countDown();
    });
    executor.execute(() -> {
        findByB服务();
        count.countDown();
    });
    try {
        count.await(1, TimeUnit.SECONDS);
    } catch (InterruptedException e) {
        // 超时了~~~
    }
    // 执行到这，代表三个操作全部反正，做汇总响应
}
```

其次，有一个JUC工具，叫CyclicBarrier，这个东西和CountDownLatch挺像，但是有一点不一样。

CountDownLatch减到0就没啥用了，不能复用。

而CyclicBarrier也是业务线程等待其他线程处理完，再继续执行，但是CyclicBarrier可以重置。

```java
@SneakyThrows
public static void findBy三方(){Thread.sleep(700);
System.out.println("查询完三方");}
@SneakyThrows
public static void findByMySQL(){Thread.sleep(200);System.out.println("查询完MySQL");}
@SneakyThrows
public static void findByB服务(){Thread.sleep(300);System.out.println("查询完B服务");}

public static void main(String[] args) {
    ExecutorService executor = Executors.newFixedThreadPool(3);
    CyclicBarrier cyclicBarrier = new CyclicBarrier(3,() -> {
        // 执行到这，代表三个操作全部反正，做汇总响应
        System.out.println("全完了。");
    });
    executor.execute(() -> {
        findBy三方();
        try {
            cyclicBarrier.await();
        } catch (Exception e) {
            e.printStackTrace();
        }
        // 再做其他操作
    });
    executor.execute(() -> {
        findByMySQL();
        try {
            cyclicBarrier.await();
        } catch (Exception e) {
            e.printStackTrace();
        }
        // 再做其他操作
    });
    executor.execute(() -> {
        findByB服务();
        try {
            cyclicBarrier.await();
        } catch (Exception e) {
            e.printStackTrace();
        }
        // 再做其他操作
    });
    // 可以重置再使用
    cyclicBarrier.reset();
}
```

##
