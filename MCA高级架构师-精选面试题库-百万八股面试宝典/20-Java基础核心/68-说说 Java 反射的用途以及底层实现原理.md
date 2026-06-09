Java 的反射机制允许程序在运行时动态地获取类的信息并操控其行为，核心在于 `java.lang.Class` 与 `java.lang.reflect.*` 包。以下围绕用途与原理展开说明。

#### 用途

1. **动态加载与解耦**  
   可以根据类全名（字符串）动态加载并实例化对象，实现插件机制、模块化设计，比如 Servlet 容器创建 servlet、Spring IOC 注入 Bean 等。M
2. **运行时检查与工具支持**  
   框架、测试库（如 Spring、JUnit）通过反射读取类结构、注解、方法等元数据，用于依赖注入、方法调用、自动测试、文档生成等 。
3. **访问私有成员与元编程**  
   通过 `setAccessible(true)` 可突破访问控制，访问私有字段和方法，用于序列化、调试、Mock 对象等场景 。S

---

#### 实现原理

- **类加载后生成 Class 对象**  
  JVM 在加载 `.class` 文件时，为每个类或接口创建对应的 `java.lang.Class` 实例，其中包含字段、方法、构造器、注解等结构化信息。
- **反射 API 读取元数据**  
  使用 `getDeclaredMethods()`, `getDeclaredFields()`, `getConstructors()` 等方法可获得 `Method`、`Field`、`Constructor` 对象，它们封装了成员的各种属性。
- **动态调用与访问过程**  
  调用 `Method.invoke()` 或 `Constructor.newInstance()` 时，JVM 内部执行安全检查、参数转换、异常处理，然后调用底层字节码指令（如 `invokevirtual`）。访问私有成员需 `AccessibleObject.setAccessible(true)`，绕开 Java 访问限制（必要时）。
- **性能与安全影响**  
  反射具有灵活性但性能较差（每次调用会检查权限、进行包装拆箱以及异常处理），且可能破坏封装，增加安全风险，因此应谨慎使用于关键路径。B
