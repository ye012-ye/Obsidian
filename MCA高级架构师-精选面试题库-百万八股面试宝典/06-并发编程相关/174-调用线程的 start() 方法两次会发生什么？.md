在 Java 中，线程的生命周期由多个状态组成，包括 NEW、RUNNABLE、RUNNING 和 TERMINATED。

当创建一个线程对象时，它处于 NEW 状态。

调用 `start()` 方法后，线程进入 RUNNABLE 状态，JVM 会调用线程的 `run()` 方法来执行任务。

一旦线程执行完 `run()` 方法，它就进入 TERMINATED 状态。

根据 Java 官方文档的描述：

"It is never legal to start a thread more than once. In particular, a thread may not be restarted once it has completed execution."

这意味着一旦线程处于 TERMINATED 状态，就无法再次调用 `start()` 方法。

**示例代码：**

```java
public class ThreadTest extends Thread {
    public void run() {
        System.out.println("Thread is running.");
    }

    public static void main(String[] args) {
        ThreadTest t = new ThreadTest();
        t.start();  // 第一次调用 start()，线程开始执行
        t.start();  // 第二次调用 start()，抛出 IllegalThreadStateException
    }
}
```

**输出：**

```php
  Thread is running.
    Exception in thread "main" java.lang.IllegalThreadStateException
    at java.base/java.lang.Thread.start(Thread.java:789)
    at ThreadTest.main(ThreadTest.java:10)
```
