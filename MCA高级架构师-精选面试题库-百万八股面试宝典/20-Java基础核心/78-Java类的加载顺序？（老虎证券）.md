我在听录音听到这个问题的时候我懵了。

这个问题问的很奇怪，具体想聊的估计只有两个

- **类加载过程**

- 加载： 先找到字节码文件（.class文件），加载到JVM内存中的方法区里。 然后在内存中的体现就是一个Class对象。
- 验证： 验证加载到内存里的.class文件是否被篡改过，确认没有安全问题，以及符合JVM规范。
- 准备： 为类中的一些变量分配内存空间，并且设置一下默认值。
- 解析： 将常量池内的符号引用转为直接引用。

- 符号引用：符号引用是一种泛指，com/mashibing/A-findAll()void
- 直接引用：直接指向的内库的具体位置，直接就是内存偏移量。后面调用会更快。

- 初始化：对所有静态变量复制，执行静态代码块，初始化好父类~~
- 前面走完，到这，这个.class就可以在Java程序中使用了，new一个对象，类名.静态方法都可以了

- **双亲委派**

- 他其实就是加载这个过程的细节，需要先掌握一下Java中默认的三种类加载器

- BootstrapClassLoader：负责加载jdk/jre/lib/rt.jar
- ExtensionClassLoader：负责加载jdk/jre/lib/ext目录下的jar文件
- ApplicationClassLoader：负责加载classpath目录下的各种class文件。 所谓的classpath，其实就是编译后的classes目录。
- 其实还有一个自定义的，你自己去继承ClassLoader，重新他的方法，指定你要加载的位置。

- 双亲委派的过程。当需要用到某个class文件时，撇掉自定义类加载器，他会按照这个方式去加载

- 先调度AppClassLoader，先查看AppClassLoader加载过么？没加载过，往上问。
- 问到ExtClassLoader，先查看ExtClassLoader加载过么？没加载过，网上问。
- 最终问到BootstrapClassLoader，先查看BootstrapClassLoader加载过么？没加载过，尝试加载！如果rt.jar里没有这个.class文件可以加载，往下分配。
- 分配到ExtClassLoader，他去尝试在ext目录下去加载，如果也没加载到，往下分配。
- 最终分配到AppClassLoader，他尝试去classpath目录下找这个.class文件加载。
- 如果没找到，也没加载到，抛一个异常，ClassNotFoundException。

- 双亲委派解决了什么问题，搞的这么麻烦？？

- 防止类的重复加载……
- 防止你破坏JDK的结构……

- 比如现在我要加载一个java.lang.String这个类！
