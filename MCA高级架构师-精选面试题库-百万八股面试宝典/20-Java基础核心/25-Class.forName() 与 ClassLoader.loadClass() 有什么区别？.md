在Java中，这两种方式都能动态加载类，但在**类初始化时机**、**使用场景**和**加载器选择**方面存在三点核心差异：

### 1. 类的初始化时机 ​

- `Class.forName("com.example.Foo")` 会**立即加载并链接**类，紧接着**执行静态初始化代码**（如 `static { ... }`）。
- `ClassLoader.loadClass("com.example.Foo")` 只完成**加载与链接**阶段，**不会触发静态初始化**，直到首次使用该类才会初始化。

### 2. 加载器控制与灵活性

- `Class.forName(...)` 默认使用调用者的类加载器（caller’s classloader），也提供重载版本接收自定义加载器、初始化标志等。
- `ClassLoader.loadClass(...)` 绑定于某个具体类加载器实例，开发者可显式控制从哪个类加载器加载资源，适用于插件、多环境加载等场景。

### 3. 使用场景差异

- 当你希望**类被初始化**（如驱动类注册、执行静态块）时，推荐使用 `Class.forName("com.driver.MyDriver")`，如旧版 JDBC 驱动初始化。
- 若你仅需查询类结构、获取元数据，却不希望执行静态块，此时应选用 `ClassLoader.loadClass(...)` 来避免副作用。

### 案例演示对比：

```java
// 使用 Class.forName()
Class.forName("com.example.MyClass");
// 将触发 static 块执行

// 使用 loadClass()
ClassLoader cl = Thread.currentThread().getContextClassLoader();
cl.loadClass("com.example.MyClass");
// 不触发 static 块，直到 new 或方法访问时才初始化
```
