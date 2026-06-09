Spring涉及到的设计模式太多了，能说几个是几个，但是一定要点到具体是哪里涉及到了。

- 单例：Spring默认维护的bean都是单例的
- 工厂：Spring内部提供了各种工厂，顶级接口是BeanFactory
- 代理：AOP底层就是基于代理实现的
- 原型：Spring可以将bean的scope属性设置为prototype。**（但是他每次都是重新基于反射构建，没用拷贝）**
- 装饰者：Spring在构建bean之后，会将器包装为BeanWrapper
- 构建者：在构建BeanDefinition的时候，属性贼多，内部提供了BeanDefinitionBuilder
- 责任链：Interceptor拦截器，多个拦截器就具备责任链的效果。
- 模板：RedisTemplate，RabbitTemplate…………各种模板~
- 策略：ClassPathXMLApplicationContext以及对应的FileSystemXmlApplicationContext
- 观察者：各种Listener，各种Event事件~~
- 委托…………………………等等
