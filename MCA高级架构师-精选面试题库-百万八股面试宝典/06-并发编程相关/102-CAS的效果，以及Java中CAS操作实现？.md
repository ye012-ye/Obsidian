CAS就是比较和交换，就是将内存中的某一个值，从oldValue，替换为newValue。替换的过程是先用oldValue比较内存值，如果一致，就替换，然后返回true。如果比较不一致，返回false。

比较和交换这两个操作是一条指令实现的。

Java中想用CAS操作的话，无法直接通过new或者是他提供的静态方法，直接使用。会抛出java.lang.SecurityException: Unsafe异常。

想用的话，unsafe类的对象需要通过反射的方式拿到。

```java
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

####
