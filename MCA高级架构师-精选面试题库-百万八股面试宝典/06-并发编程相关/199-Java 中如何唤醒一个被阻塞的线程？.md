Java 中常见阻塞机制包括以下几种：`Thread.sleep()`、`Object.wait()`、`Condition.await()`、`Lock.lock()` 等。当线程因调用这些方法而进入阻塞状态时，通常可以通过 `Thread.interrupt()` 或同步通知机制进行唤醒。

### 一、通过 `Thread.interrupt()` 唤醒阻塞线程

调用 `thread.interrupt()` 可以中断目标线程的等待状态，使其抛出 `InterruptedException` 并尽早恢复执行。需要注意：仅对那些支持中断的阻塞方法有效，如 `sleep()`、`wait()`、`join()` 或 `Condition.await()` 等方法；普通 I/O 操作的响应行为则依赖于 JVM 和底层操作系统，可能抛出 IOException，也可能不响应。

**示例代码：**

```java
Thread t = new Thread(() -> {
    try {
        Thread.sleep(10000); // 模拟阻塞
    } catch (InterruptedException e) {
        System.out.println("被中断并唤醒：" + Thread.currentThread().getName());
    }
});
t.start();
Thread.sleep(1000);
t.interrupt(); // 唤醒阻塞线程
```

### 二、使用 `wait()/notify()` 或 `Condition.await()/signal()` 通知唤醒

使用 `synchronized` 块时，可通过 `Object.wait()` 使线程等待，并由另一个线程调用同一对象的 `notify()` 或 `notifyAll()` 唤醒等待线程。这种方式用于线程间显式的条件协调，而非线程强制中断。

**示例代码：**

```java
synchronized(shared) {
    shared.wait(); // 线程释放锁并等待
}

// 另一线程中：
synchronized(shared) {
    shared.notifyAll(); // 唤醒所有等待线程
}
```

使用 `Lock` 与 `Condition` 时也类似：

```java
awaitLock.await();  // 进入阻塞等待
signalLock.signal(); // 唤醒其中一个
```

这种机制无需检查中断状态，适用于线程间协作逻辑，而不是外部中断控制。

### 三、选择唤醒方式的适用场景对比

|  |  |  |  |
| --- | --- | --- | --- |
| **唤醒方式** | **作用目标** | **阻塞类型** | **使用场景** |
| `thread.interrupt()` | 指定线程 | sleep、wait、await 等 | 用于取消/终止线程、超时控制、任务中断等场景 |
| `notify()/notifyAll()` | 等待同一 monitor 的线程 | `Object.wait()`  等 | 用于线程间协调条件、生产者消费者等同步场景 |
| `Condition.signal()/all()` | 等待同一 condition 的线程 | `await()` | 与 `Lock`  配合使用，实现灵活同步控制 |

### 四、代码示例对比

```java
// 1. 中断式唤醒
Thread t = new Thread(() -> {
    try {
        Thread.sleep(5000);
    } catch (InterruptedException e) {
        // 处理中断逻辑
        Thread.currentThread().interrupt(); 
    }
});
t.start();
t.interrupt();

// 2. wait/notify 模式
synchronized(queue) {
    while (queue.isEmpty()) {
        queue.wait();
    }
    // 获取队列内容
}

synchronized(queue) {
    queue.add(item);
    queue.notifyAll(); // 唤醒等待者
}
```
