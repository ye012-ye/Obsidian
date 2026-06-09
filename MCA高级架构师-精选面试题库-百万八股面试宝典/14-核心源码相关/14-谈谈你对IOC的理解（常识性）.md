**解耦：**

- IOC就是帮你创建对象，同时将对象地址扔到引用里。
- 某个通过IOC，各个模块之间的对象耦合性变的更低。
- 比如远古时期，一个Service层如果依赖DAO，那会直接new一个DaoImpl的实例。使用了IOC之后，基于接口的引用，利用IOC将依赖通过Spring容器注入进来，就可以扔Service和DAO之间的耦合更低。
- 比如现在有一个CacheService，可能之前使用的是MemCacheServiceImpl的实例，利用Spring直接基于CacheService接口注入进去。如果后期要换成RedisSerivceImpl，所有引用CacheService实例的对象不需要做任何变化。

**底层相关：**

前面聊清楚自己的想法后，可以再点一嘴Spring是怎么实现IOC的，他的本质就是在程序启动时，先加载xml以及注解的相关内容，获取bean的一些元数据，将这些元数据封装为BeanDefinition的实例，扔到一个集合中，当要创建bean时，获取到每一个BeanDefinition，基于反射的形式将对象构建出来，并且扔到一级缓存中，哪里需要注入，就从一级缓存中拿！
