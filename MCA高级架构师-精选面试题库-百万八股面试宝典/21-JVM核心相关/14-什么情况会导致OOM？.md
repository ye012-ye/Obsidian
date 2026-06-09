参考回答：

（1）深度的方法调用 StackOverFlowError

（2）堆内存溢出 OutOfMemoryError: Java heap space

（3）清理垃圾，但是很快又填满 GC overhead

（4）nio程序在分配本地内存的时候，本地内存用光了，内存用光之后，当再次分配内存的时候，程序就崩了。

（5）MetaspaceOOM （重复吃Aug年间静态类变量）

（6）一个应用进程创建了多个线程超出了系统的限制，linux默认1024，可以通过修改其中的linux服务器配置解决。

## ​
