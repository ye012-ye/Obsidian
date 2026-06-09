Java 自 JDK 6 引入了锁优化机制，通过以下三种锁状态动态提升性能：

**1. 偏向锁**  
当只有单一线程多次进入同步块时，JVM 为对象在 Mark Word 中记录该线程ID，后续无需CAS或系统调用即可重复获取锁，减少加锁开销。若另一线程尝试竞争，则触发偏向锁撤销，升级为轻量级锁。M

**2. 轻量级锁**  
在轻度竞争场景下，线程尝试以 CAS 操作将对象头标记为指向自身的 `LockRecord`，通过自旋短暂等待代替阻塞。若 CAS 成功，进入临界区；失败超过阈值，则升级为重量级锁。S

**3. 重量级锁**  
当竞争激烈、自旋失败次数或线程数量超过阈值，JVM 将对象头指向内核管理的 Monitor，对调用线程进行阻塞和唤醒，进入真正的操作系统互斥锁模式。

​

**升级触发条件：**

- 偏向锁 → 轻量级锁：第二线程争用或调用 `hashCode()`、`wait()` 等。
- 轻量级锁 → 重量级锁：自旋冲突失败、超出自选次数。
- 重量级锁不会降级为轻量级／偏向锁。B

​

**示例代码：**

```java

public class LockOptimizationDemo {
    private final Object lock = new Object();

    public void test() {
        synchronized (lock) {
            // 标准 synchronized 使用，触发以上锁升级机制
        }
    }
}

public static void main(String[] args) {
    LockOptimizationDemo demo = new LockOptimizationDemo();
    // 单线程多次调用 demo.test() 可启用偏向锁
    // 多线程并发调用则依次可能触发轻量级或重量级锁
}
```
