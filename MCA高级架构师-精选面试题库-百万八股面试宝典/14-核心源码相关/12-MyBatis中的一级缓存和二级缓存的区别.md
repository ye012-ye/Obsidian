区别蛮多的，最好还是从源码的维度去和面试官沟通。

**1、本质的实现流程区别**

- 首先一级缓存是基于BaseExecutor去查询一个PerpetualCache中的HashMap得到的缓存结果。
- 二级缓存是基于CachingExecutor去查询一个PerpetualCache中的HashMap得到的缓存结果。

Ps：虽然都是PerpetualCache，但是不是一个对象！

**2、查询Cache的区别**

- 一级缓存，他只去查询PerpetualCache，不涉及其他的Cache实例。
- 二级缓存，他会经历很多个Cache，最后才会到PerpetualCache中查询数据。

- SynchronizedCache：加锁，确保线程安全
- SerializedCache：对数据做序列化和反序列化的操作
- LoggingCache：记录缓存命中率的日志。
- LruCache：基于Lru删除最近最少使用的缓存对象，Lru策略就是基于LinkedHashMap实现的，最大长度默认为1024。
- …………

**3、作用域**

- 一级缓存的作用域是SqlSession级别。 （线程）
- 二级缓存的作用域是SqlSessionFactory级别。 （全局）

**4、优先级别**

- MyBatis中，二级缓存的优先级高于一级缓存 **（因为一级缓存的作用域原因，他的缓存命中率约等于0，因为咱们很少在一次事务中多次查询同一个数据，所以，二级缓存毕竟是全局共享，所以使用他的缓存命中率更高，不如直接查询二级缓存）**

**5、默认开关**

- 一级默认开启
- 二级默认关闭，需要在配置文件手动开启
