聊Spring循环依赖的思路。

1、先说清楚循环依赖的问题是怎么出现的。

2、再说解决循环依赖的方式，这里从三个维度聊

- 提前暴露对象引用
- 二级缓存
- 三级缓存（AOP）

---

先说清楚循环依赖的问题是怎么出现的：

- 有两个实例，A和B。
- 其中A中的属性引用了B，B中的属性引用了A。（A和B之间相互引用）

```plain
class A{
    B b;
}
class B{
    A a;
}
```

- 利用Spring来构建这两个实例。
- 先实例化A，A在初始化的时候，需要将b属性赋值，b的实例需要去Spring容器中找。
- 因为b还没有实例化，需要去实例化B，B也需要初始化，需要去Spring容器中找A实例。

- 如果非完成初始化的A无法没使用，那就会出现循环依赖。
- But，Spring可以用非完成初始化的A实例。

Spring解决这个问题的方式：

- Spring是允许将未完成初始化的实例提前暴露出来使用的，所以上述的流程不会出现循环依赖的问题。
- 而二级缓存就是分别存储提前暴露出来的对象，以及完成初始化的对象，可以提前去这里查看提供的二级缓存分别是啥。

```plain
public class DefaultSingletonBeanRegistry ……{
        /** 一级缓存，存储完成初始化的对象 */
    private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

    /** 二级缓存，存储提前暴露出来的对象 */
    private final Map<String, Object> earlySingletonObjects = new ConcurrentHashMap<>(16);
}
```

- 面试官可能会问，二级缓存已经够了，为啥Spring提供了三级缓存呢？

- 因为咱们Spring提供了AOP的机制，如果某个bean需要被代理，需要将代理对象提前暴露出来，不能对外暴露未代理的对象。
- 而Spring提供的三级缓存，他存储的ObjectFactory类型，他是一个函数式接口，三级缓存中本质存储的是一个Lambda表达式，需要获取对应的对象时，需要调用这个ObjectFactory中的getObject方法才能获取。
- 这样如果对象需要被代理，就可以基于三级缓存中提供的getObject的方式将对象代理后，再从三级缓存中拿到二级或者一级缓存。

**如果Spring没有AOP的这个机制需要处理，那其实二级缓存已经足够了。 But，Spring有代理的操作，所以他需要这个三级缓存，来将bean的代理对象构建出来返回。**
