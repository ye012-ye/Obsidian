一般用于限流比较多一些。

如果当前某个操作要做限流，比如最多有10个线程并行执行这个操作。

那就可以用Semaphore。

```java
// 这个就是信号量，有10个资源，每个线程拿一个资源，才能去做某个操作。
static Semaphore semaphore = new Semaphore(10);

/**
 * 最多10个线程并行玩。
 */
public static void 某个操作(){}

public static void main(String[] args) throws Exception {
    boolean b = semaphore.tryAcquire(1000, TimeUnit.MILLISECONDS);
    if(b){
        try {
            某个操作();
        } finally {
            semaphore.release();
        }
    }else{
        // …………
    }
}

```
