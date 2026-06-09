```plain
public class MyTest {

    private int value = 1;

    public static void main(String[] args) throws Exception {
        MyTest test = new MyTest();
        Unsafe unsafe = null;
        Field field = Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);
        unsafe = (Unsafe) field.get(null);
        // 获取内存偏移量
        long offset = unsafe.objectFieldOffset(MyTest.class.getDeclaredField("value"));
        // 执行CAS，这里的四个参数分别代表什么，你也要清楚~
        System.out.println(unsafe.compareAndSwapInt(test, offset, 0, 11));
        System.out.println(test.value);
    }

}
```

CAS就是将内存中的某一个属性，从oldValue，替换为newValue。保证原子性。

**1、Java层面如何实现的CAS以及使用。**

在Java中，是基于Unsafe类提供的native方法实现的。native是走的C++的依赖库

```plain
public final native boolean cas(Object 哪个对象, long 内存偏移量, Object 旧值, Object 新值);

public final native boolean compareAndSwapInt(Object var1, long var2, int var4, int var5);

public final native boolean compareAndSwapLong(Object var1, long var2, long var4, long var6);
```

Unsafe类，不能直接new，只能通过反射的形式获取到Unsafe的实例去操作，不过一般业务开发中，基本不会直接使用到Unsafe类。

**2、Java的CAS在底层是如何实现的。**

Java层面的CAS，只到native方法就没了。底层是C++实现的，但是其实比较和交换（CAS），是**CPU支持的原语**。**cmpxchg指令**就是CPU支持的原语。

如果在CPU层面，多核CPU并行执行CAS修改同一个属性，可能会导致出现问题。C++内部就可以看到针对**cmpxchg指令**前追加了**lock前缀指令**（多核CPU）

**3、CAS存在的一些问题**

- **ABA问题：** 要修改的数据，最开始是A，但是你没修改成功，期间经过一些列的操作，后来又变回了A，此时你CAS会成功。 但是这个数据在最开始的A ---- 最后的A，这期间发生了什么事情，咱不清楚。如果业务有要求这个期间发生的问题也要纠结一下，那么你就需要换一种CAS的实现实现。利用版本号来确认。Java中提供了解决这种ABA问题的原子类。

```plain
public class AtomicStampedReference<V> {

    private static class Pair<T> {
        final T reference;   // 你要修改的值
        final int stamp;     // 版本号，你可以自行制定  戳~
    }
}
```

- **性能问题：** CAS的性能嘎嘎快，一个层面是他属于CPU原语层面上的指令。还有一个优点，CAS会返回成功还是失败，不会挂起线程。但是如果基于while这种循环操作去调度CAS直到成功，那可能会优点消耗CPU的资源了，一直执行CAS指令，但是一段是时间无法成功。 如果你感觉短期内就能ok，那就上CAS，如果不成，使用悲观锁（synchronized，lock锁）

**自旋锁，CAS，乐观锁，自适应自旋锁。**

- 乐观锁：是一种泛指，Java有Java的乐观锁实现，MySQL也有自己的乐观锁实现。（不会挂起线程）
- 悲观锁：也是一种泛指，认为拿不到资源，拿不到就挂起线程。
- CAS：Java中的乐观锁实现，是CAS。CAS对于Java来说，就是一个方法，做一次比较和交换。（不会挂起线程，线程的状态从运行到阻塞）
- 自旋锁：你可以自己实现，就是循环去执行CAS，知道成功为止。

```plain
while(!cas()){}
for(;;;){ if(cas)  return }
```

- 自适应自旋锁： 这个东西就是synchronized的轻量级锁用到了，相对智能的自旋锁，如果上次CAS成功了，这次CAS循环次数，加几次。如果上次失败了，这次CAS就减几次。
