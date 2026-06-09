1、~~单词不一样~~（面试别说。。）

2、synchronized是关键字，lock是一个类。

3、synchronized就同步方法，同步代码块的使用方式，lock需要调用API。

4、从性能的维度来说，他俩几乎没有什么区别。（在JDK1.6synchronized优化之后）

5、从功能丰富的角度来说，lock更灵活，功能更丰富。

6、比如synchronized会自动释放锁资源，lock锁必须确保unlock要执行，最好扔fianlly里。

7、synchronized竞争锁是基于C++的方式，利用CAS修改owner竞争锁，ReentrantLock是基于CAS修改state属性，从0改为1。

**Ps：synchronized中的偏向锁在JDK15被废弃，20中被完全移除了，因为偏向锁撤销需要等待安全点，很耗时，他不但没法优化，反而会导致一定的性能下降，so，在JDK15被干掉了。。。**

…………
