**避免指令重排，获取到未初始化完成的对象。**

单例模式的懒汉模式确保线程安全的机制DCL

```java
public class MyTest {

    private static MyTest myTest;

    public static MyTest getInstance(){
        if(myTest == null) {            // check
            synchronized (MyTest.class) {   // lock
                if(myTest == null) {    // check
                    myTest = new MyTest();
                }
            }
        }
        return myTest;
    }
}
```

DCL正常可以解决单例模式的安全问题，但是由于CPU可能会对程序的一些指令做出重新的排序，导致出现拿到一些未初始化完成的对象去操作，最常见的就是出现了诡异的NullPointException。

**（扩展一下）volatile修饰myTest对象后，可以禁止CPU做指令重排。volatile的生成字节码指令后有内存屏障（指令），内存屏障会被不同的CPU翻译成不同的函数，比如X86的CPU，会对StoreLoad内存屏障翻译成mfence的函数，最终的指令就是lock前缀指令。**

Java中new对象，可以简单的看成三个指令的操作。

- 1、开辟内存空间
- 2、初始化对象内部属性
- 3、将内存空间的地址赋值给引用
