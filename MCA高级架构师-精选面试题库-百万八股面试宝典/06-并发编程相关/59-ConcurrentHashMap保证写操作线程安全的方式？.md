![](../assets/c8786960c6a8cd97.png)

数组上扔数据，CAS保证安全。

链表/红黑树扔数据，synchronized锁数组元素保证线程安全。

JDK1.7中的ConcurrentHashMap是基于分段锁来保证的线程安全。

![](../assets/d5ddc456f1f288c4.png)
