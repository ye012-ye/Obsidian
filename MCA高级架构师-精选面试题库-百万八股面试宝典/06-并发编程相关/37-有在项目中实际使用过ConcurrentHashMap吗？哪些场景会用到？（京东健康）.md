ConcurrentHashMap本质就是做缓存的！将一些热点数据甩到ConcurrentHashMap里，他的速度比Redis快。毕竟你找Redis要数据，还得走一个网络IO的成本，ConcurrentHashMap就是JVM内部的数据。

比如数据已经从MySQL同步到Redis里了，但是Redis的性能不达标，或者Redis节点本身压力就比较大。那咱们就可以将缓存前置到JVM缓存中，利用ConcurrentHashMap去存储。

但是这种方式存储，如果JVM节点是集群部署，那就必然会存在不一致的问题。

- 强行走强一致，让你的缓存的存在没啥意义。。。（不这么玩）
- 通过一些中间件，MQ，Zookeeper等都可以做大监听通知或者广播的效果，这种同步可能存在延迟，达到最终一致性。
- 将一些访问量特别频繁的数据，扔到JVM内存，就生存1s甚至更少，这样可以较少对Redis的压力……同时在短时间内，也能提升性能……

类似Nacos，Eureka这种注册中心，就用到了ConcurrentHashMap，将注册中心里的注册列表的所有服务信息拉取到本地的ConcurrentHashMap中。

Spring的三级缓存用的啥？？不也是ConcurrentHashMap么~~BeanDefinition
