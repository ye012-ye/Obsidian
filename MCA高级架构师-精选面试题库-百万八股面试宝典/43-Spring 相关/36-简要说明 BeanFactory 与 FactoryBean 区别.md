Spring 中这两者虽然名字相似，但角色截然不同：

#### 1. 核心定位

- **BeanFactory**：Spring IoC 容器的顶层接口，管理、装配并提供 Bean 的实例，是整个容器的基础。M
- **FactoryBean**：一种特殊的 Bean，是由开发者实现的工厂类，用于封装复杂对象的创建逻辑，Spring 调用其 `getObject()` 方法生成最终 Bean。

S

#### 2. 角色与职责

- **BeanFactory** 负责管理 Bean 生命周期、依赖注入、延迟加载等操作。
- **FactoryBean** 只专注于“如何创建某个 Bean”，比如第三方资源、动态代理、复杂初始化等场景。

#### 3. 获取方式

- `context.getBean("beanName")` 返回 FactoryBean 生成的实际对象。
- `context.getBean("&beanName")` 返回 FactoryBean 自身的实例（带 `&` 前缀用于区分）。

#### 4. 使用场景

- **BeanFactory**：框架基础设施，通常由 Spring 提供实现，开发者一般不会自己实现。
- **FactoryBean**：当某个 Bean 的生成需要自定义逻辑时，例如 MyBatis Mapper 的动态代理，JPA `EntityManagerFactory` 的初始化等。B  
  MyBatis 的 `MapperFactoryBean` 就是典型案例，Spring 扫描接口并自动创建代理对象。

#### 5. 示例对比

```java
// FactoryBean 示例
public class UserFactoryBean implements FactoryBean<UserService> {
    @Override
    public UserService getObject() {
        // 封装复杂创建逻辑
        return new UserServiceImpl(/* 可能带配置、连接等 */);
    }
    @Override public Class<?> getObjectType() { return UserService.class; }
    @Override public boolean isSingleton() { return true; }
}
```

注入方式如下：

```java
// 获取 product 对象
UserService svc = context.getBean("userFactoryBean", UserService.class);
// 获取 factory 自身
UserFactoryBean factory = context.getBean("&userFactoryBean", UserFactoryBean.class);
```

### 总结

|  |  |  |
| --- | --- | --- |
| **比较维度** | **BeanFactory** | **FactoryBean** |
| **定位** | IoC 容器接口，管理 Bean | 特殊工厂 Bean，生成其它 Bean |
| **实现者** | Spring 提供（如 ApplicationContext） | 开发者实现 |
| **获取方式** | getBean("name") 获得 Bean | getBean("&name") 获得 Factory |
| **应用场景** | 容器管理 | 自定义复杂创建流程 |
