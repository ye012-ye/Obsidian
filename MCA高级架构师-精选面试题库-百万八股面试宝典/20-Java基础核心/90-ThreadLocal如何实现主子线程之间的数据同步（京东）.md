用共享变量去实现父子线程之间的数据同步。

一般面试要聊InheritableThreadLocal，一定是父线程主动的去创建的子线程才可以。

如果是子线程给父线程传递数据，那就是采用共享编程，或者作为返回值。

具体的实现原理，看这个。

> <https://www.mashibing.com/course/2751>
>
> ![](../assets/09bc914a8e3b91a8.png)

## ​
