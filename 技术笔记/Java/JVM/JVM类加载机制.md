---
title: JVM类加载机制
tags:
  - JVM
  - 类加载
  - 双亲委派
  - 面试
created: 2026-04-07
up: "[[JVM底层原理 - 总览]]"
---

# JVM 类加载机制

## 类的生命周期

```mermaid
graph LR
    A["加载<br/>Loading"] --> B["验证<br/>Verification"]
    B --> C["准备<br/>Preparation"]
    C --> D["解析<br/>Resolution"]
    D --> E["初始化<br/>Initialization"]
    E --> F["使用<br/>Using"]
    F --> G["卸载<br/>Unloading"]
    
    subgraph 连接["连接 Linking"]
        B
        C
        D
    end
    
    style A fill:#a5d6a7
    style B fill:#bbdefb
    style C fill:#bbdefb
    style D fill:#bbdefb
    style E fill:#ffcc80
```

### 各阶段详解

#### 1. 加载（Loading）

```mermaid
graph TD
    A["加载阶段做三件事"]
    A --> B["1.通过全限定名获取<br/>二进制字节流（.class）"]
    A --> C["2.将字节流的静态存储结构<br/>转化为方法区的运行时数据"]
    A --> D["3.在堆中生成<br/>java.lang.Class 对象<br/>（类的访问入口）"]
```

字节流来源可以是：
- `.class` 文件
- JAR / WAR 包
- 网络传输
- 运行时动态生成（动态代理）

#### 2. 验证（Verification）

确保 Class 文件符合 JVM 规范，不会危害虚拟机安全。

```
✅ 文件格式验证：魔数 0xCAFEBABE、版本号
✅ 元数据验证：父类是否存在、是否继承了 final 类
✅ 字节码验证：指令合法性、类型安全
✅ 符号引用验证：引用的类/方法/字段是否存在
```

#### 3. 准备（Preparation）

为**类变量**（static 变量）分配内存并设置**零值**。

```java
// 准备阶段：
public static int value = 123;  // value = 0（零值！不是123）
public static final int CONST = 456;  // CONST = 456（final 是常量，直接赋值）
```

```mermaid
graph TD
    A["准备阶段赋零值"]
    A --> B["int → 0"]
    A --> C["long → 0L"]
    A --> D["boolean → false"]
    A --> E["float → 0.0f"]
    A --> F["引用类型 → null"]
    A --> G["⚠️ static final 常量 → 直接赋实际值"]
    
    style G fill:#fff9c4
```

#### 4. 解析（Resolution）

将常量池中的**符号引用**替换为**直接引用**（内存地址）。

```
符号引用：  "java/lang/Object"（文本描述）
     ↓ 解析
直接引用：  0x7F3A2B00（实际内存地址/偏移量）
```

#### 5. 初始化（Initialization）

执行类的 `<clinit>()` 方法（编译器自动生成），真正执行 static 变量赋值和 static 代码块。

```java
public class Example {
    static int a = 10;        // <clinit>() 中：a = 10
    static {
        System.out.println("静态代码块");  // <clinit>() 中执行
    }
}
```

> [!important] 触发类初始化的 6 种场景（主动引用）
> 1. `new` 对象、读写静态字段（非 final）、调用静态方法
> 2. 反射调用 `Class.forName()`
> 3. 初始化子类时，父类先初始化
> 4. main 方法所在的类
> 5. JDK 7 `MethodHandle` 解析结果
> 6. JDK 8 接口中的 default 方法

**不会触发初始化的场景（被动引用）：**

```java
// ❌ 不会触发 SubClass 初始化（通过子类引用父类的静态字段）
System.out.println(SubClass.parentStaticField);

// ❌ 不会触发初始化（数组定义）
SuperClass[] arr = new SuperClass[10];

// ❌ 不会触发初始化（引用常量）
System.out.println(ConstClass.FINAL_VALUE);
```

---

## 类加载器

```mermaid
graph TD
    A["Bootstrap ClassLoader<br/>启动类加载器<br/>━━━━━━━━━━━━<br/>加载: rt.jar, java.lang.*<br/>C++ 实现，Java 中为 null"]
    
    B["Extension ClassLoader<br/>扩展类加载器<br/>━━━━━━━━━━━━<br/>加载: jre/lib/ext/*.jar<br/>JDK 9 → Platform ClassLoader"]
    
    C["Application ClassLoader<br/>应用类加载器<br/>━━━━━━━━━━━━<br/>加载: classpath 下的类<br/>我们写的代码默认用这个"]
    
    D["Custom ClassLoader<br/>自定义类加载器<br/>━━━━━━━━━━━━<br/>继承 ClassLoader<br/>重写 findClass()"]
    
    A --> B --> C --> D
    
    style A fill:#e1bee7
    style B fill:#bbdefb
    style C fill:#c8e6c9
    style D fill:#fff9c4
```

---

## 双亲委派模型

### 核心流程

```mermaid
graph TD
    A["请求加载 java.lang.String"]
    A --> B["Application ClassLoader<br/>我能加载吗？先问父亲"]
    B -->|"委派给父"| C["Extension ClassLoader<br/>我能加载吗？先问父亲"]
    C -->|"委派给父"| D["Bootstrap ClassLoader<br/>我在 rt.jar 中找到了！"]
    D -->|"加载成功 ✅"| E["返回 Class 对象"]
    
    F["请求加载 com.example.MyClass"]
    F --> G["Application ClassLoader<br/>先问父亲"]
    G -->|"委派"| H["Extension ClassLoader<br/>先问父亲"]
    H -->|"委派"| I["Bootstrap ClassLoader<br/>找不到 ❌"]
    I -->|"返回失败"| J["Extension ClassLoader<br/>我也找不到 ❌"]
    J -->|"返回失败"| K["Application ClassLoader<br/>我在 classpath 找到了！✅"]
    
    style D fill:#a5d6a7
    style K fill:#a5d6a7
```

### 源码级理解

```java
protected Class<?> loadClass(String name, boolean resolve) {
    // 1. 先检查类是否已经被加载
    Class<?> c = findLoadedClass(name);
    if (c == null) {
        try {
            if (parent != null) {
                // 2. 委派给父加载器
                c = parent.loadClass(name, false);
            } else {
                // 3. 没有父加载器，用 Bootstrap
                c = findBootstrapClassOrNull(name);
            }
        } catch (ClassNotFoundException e) {
            // 父加载器加载失败
        }
        if (c == null) {
            // 4. 父加载器都失败了，自己尝试加载
            c = findClass(name);
        }
    }
    return c;
}
```

```mermaid
graph TD
    A["loadClass(name)"] --> B{"已经加载过？"}
    B -->|"是"| C["直接返回 ✅"]
    B -->|"否"| D{"有父加载器？"}
    D -->|"有"| E["parent.loadClass(name)"]
    D -->|"没有"| F["findBootstrapClass(name)"]
    E --> G{"父加载成功？"}
    F --> G
    G -->|"成功"| C
    G -->|"失败"| H["自己 findClass(name)"]
    H --> I{"自己加载成功？"}
    I -->|"成功"| C
    I -->|"失败"| J["ClassNotFoundException ❌"]
```

### 双亲委派的好处

```mermaid
graph TD
    A["双亲委派的好处"]
    A --> B["1. 安全性<br/>防止核心类被篡改"]
    A --> C["2. 唯一性<br/>同一个类只加载一次"]
    
    B --> B1["即使你写了 java.lang.String<br/>也会被 Bootstrap 加载真正的<br/>不会用你写的恶意版本"]
    
    C --> C1["所有类加载器加载的 String<br/>都是同一个 Class 对象"]
```

> [!important] 面试标准答案
> **双亲委派的好处：**
> 1. **避免类的重复加载**：父加载器已加载的类，子加载器不会重复加载
> 2. **保护核心类库安全**：防止自定义类覆盖核心 API（如自定义 `java.lang.String`）

---

## 打破双亲委派

### 什么时候需要打破？

| 场景 | 说明 |
|------|------|
| **SPI 机制** | DriverManager（Bootstrap）需要加载用户的 JDBC 驱动（App ClassLoader） |
| **热部署** | Tomcat 不同 Web 应用需要加载不同版本的同名类 |
| **模块化** | OSGi、JDK 9 Module System |

### SPI 打破双亲委派

```mermaid
graph TD
    A["问题：DriverManager 由 Bootstrap 加载"]
    A --> B["但 MySQL 驱动在 classpath<br/>Bootstrap 看不到"]
    B --> C["解决：线程上下文类加载器<br/>Thread.currentThread()<br/>.getContextClassLoader()"]
    C --> D["父加载器委托子加载器加载<br/>打破了双亲委派！"]
    
    style D fill:#ffcc80
```

```mermaid
sequenceDiagram
    participant B as Bootstrap ClassLoader
    participant TCL as 线程上下文类加载器<br/>(App ClassLoader)
    
    B->>B: 加载 DriverManager
    B->>B: DriverManager 需要加载驱动
    Note over B: Bootstrap 在 rt.jar 找不到驱动
    B->>TCL: 通过线程上下文类加载器<br/>加载 com.mysql.jdbc.Driver
    TCL-->>B: 加载成功 ✅
    
    Note over B,TCL: 父加载器反向委托子加载器<br/>= 打破双亲委派
```

### Tomcat 的类加载器

```mermaid
graph TD
    A["Bootstrap ClassLoader"]
    B["Extension ClassLoader"]
    C["Application ClassLoader"]
    D["Common ClassLoader<br/>（Tomcat 公共库）"]
    E["Catalina ClassLoader<br/>（Tomcat 自身）"]
    F["Shared ClassLoader<br/>（Web 应用共享）"]
    G["WebApp ClassLoader 1<br/>（Web应用1 独立加载）"]
    H["WebApp ClassLoader 2<br/>（Web应用2 独立加载）"]
    
    A --> B --> C --> D
    D --> E
    D --> F
    F --> G
    F --> H
    
    style G fill:#c8e6c9
    style H fill:#c8e6c9
```

**Tomcat 的 WebAppClassLoader 打破双亲委派：**
1. 先在自己的 `/WEB-INF/classes` 和 `/WEB-INF/lib` 中查找
2. 找不到才委派给父加载器
3. 这样不同 Web 应用可以使用**不同版本**的同名类（如 Spring 4 和 Spring 5）

---

## 面试高频问题

### Q1：什么是双亲委派？

收到类加载请求时，先委派给父类加载器加载，父类加载器找不到再自己加载。保证了类的唯一性和核心类库的安全性。

### Q2：什么时候会打破双亲委派？怎么打破？

1. **SPI 机制**：通过线程上下文类加载器，让父加载器委托子加载器加载
2. **Tomcat**：自定义 WebAppClassLoader，优先加载自己目录下的类
3. **热部署**：每次部署用新的 ClassLoader 加载

打破方式：重写 `loadClass()` 方法（双亲委派的逻辑在这个方法里）。

### Q3：类的加载过程？

加载 → 验证 → 准备 → 解析 → 初始化。准备阶段赋零值，初始化阶段赋真正的值。

### Q4：JVM 判断两个类是否相同的条件？

**全限定名相同 + 类加载器相同**。同一个 class 文件被不同的 ClassLoader 加载，被视为不同的类。
