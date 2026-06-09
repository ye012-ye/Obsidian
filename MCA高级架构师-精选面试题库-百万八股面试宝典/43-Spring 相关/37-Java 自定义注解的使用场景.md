Java 自定义注解是一种用于为代码元素（类、方法、字段等）添加元数据的机制，非常适合以下场景：

1. **配置与扩展框架**：  
   如 Spring 的 `@Autowired`、`@RequestMapping`，可通过注解标注并由框架解析注入依赖或路由处理。M
2. **运行时验证或行为驱动**：  
   如 JUnit 的 `@Test` 或校验注解，可通过反射扫描并触发指定逻辑。
3. **代码生成或工具辅助**：  
   利用注解驱动编译时注解处理器生成代码；或运行时序列化框架基于注解控制哪些字段参与操作。S

### 自定义注解定义

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Monitor {
    long threshold() default 500;
    String level() default "INFO";
}
```

- `@Retention(RUNTIME)`：允许在运行时通过反射获取注解信息
- `@Target(METHOD)`：仅能用于方法
- 包含属性：`threshold` 和 `level`，带默认值

B

### 注解解析示例

```java
for (Method m : clazz.getDeclaredMethods()) {
    if (m.isAnnotationPresent(Monitor.class)) {
        Monitor mo = m.getAnnotation(Monitor.class);
        System.out.println("Monitor on " + m.getName()
                           + ": threshold=" + mo.threshold()
                           + ", level=" + mo.level());
    }
}
```

1. 扫描指定类的方法
2. 判断方法是否有 `@Monitor` 注解
3. 获取注解实例，读取属性并触发相应逻辑，例如日志监控

S
