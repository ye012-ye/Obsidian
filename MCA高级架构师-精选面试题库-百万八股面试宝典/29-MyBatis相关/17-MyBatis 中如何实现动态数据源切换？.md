MyBatis 本身不直接支持动态切换数据源，但在 Spring 环境中可结合 `AbstractRoutingDataSource` 和 AOP 实现灵活切换，流程如下：M

#### 1. 创建路由数据源（AbstractRoutingDataSource）

通过继承 Spring 的 `AbstractRoutingDataSource`，实现 `determineCurrentLookupKey()` 方法，从 `ThreadLocal` 中获取当前数据源标识并返回。Spring 在执行 `getConnection()` 时根据该标识路由到对应数据源。

#### 2. 使用 ThreadLocal 保存上下文

定义一个 `DataSourceContextHolder`，使用 `ThreadLocal` 存储当前线程的数据源标识。提供 `set()/get()/clear()`，确保线程安全。

#### 3. 使用 AOP 或注解切换

采用 AOP 切面或自定义注解（如 `@TargetDataSource("slave")`）在方法执行前设置数据源标识，执行完后清除。典型实现是在 `@Before` 切面中调用 `DataSourceContextHolder.set(...)`，`@After` 中清理。

#### 4. 将路由数据源注入 MyBatis

在 Spring 配置中，将 `AbstractRoutingDataSource` 实例作为 MyBatis 的 `SqlSessionFactoryBean` 或 `SqlSessionTemplate` 的 dataSource。这样 Mapper 接口调用时会动态使用当前线程所选的数据源。

S

### 示例：

```java
public class DynamicRoutingDataSource extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        return DataSourceContextHolder.getDataSourceKey();
    }
}
```

```java
public class DataSourceContextHolder {
    private static final ThreadLocal<String> context = new ThreadLocal<>();
    public static void setDataSourceKey(String key) { context.set(key); }
    public static String getDataSourceKey() { return context.get(); }
    public static void clear() { context.remove(); }
}
```

```java
@Aspect @Component @Order(0)
public class DataSourceAspect {
    @Before("@annotation(ds)")
    public void beforeSwitch(TargetDataSource ds) {
        DataSourceContextHolder.setDataSourceKey(ds.value());
    }
    @After("@annotation(ds)")
    public void afterSwitch(TargetDataSource ds) {
        DataSourceContextHolder.clear();
    }
}
```

```xml
<bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
  <property name="dataSource" ref="dynamicRoutingDataSource"/>
  <!-- 其他配置 -->
</bean>
```

B
