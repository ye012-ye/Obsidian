---
title: JVM内存模型与运行时数据区
tags:
  - JVM
  - 内存模型
  - 堆
  - 栈
  - 面试
created: 2026-04-07
up: "[[JVM底层原理 - 总览]]"
---

# JVM 内存模型与运行时数据区

这是 JVM 面试的**第一个问题**，几乎 100% 会问。先把这张图刻进脑子里。

## 五大运行时数据区

```mermaid
graph TB
    subgraph 线程共享["线程共享区域"]
        HEAP["堆 Heap<br/>━━━━━━━━━━━━━━━<br/>🟥 所有对象实例<br/>🟥 数组<br/>🟥 GC 的主战场<br/>━━━━━━━━━━━━━━━<br/>⚠️ OOM: Java heap space"]
        
        MA["方法区 Method Area<br/>━━━━━━━━━━━━━━━<br/>🟦 类信息（Class）<br/>🟦 常量池<br/>🟦 静态变量<br/>🟦 JIT 编译后的代码<br/>━━━━━━━━━━━━━━━<br/>⚠️ OOM: Metaspace"]
    end
    
    subgraph 线程私有["线程私有区域"]
        VS["虚拟机栈 VM Stack<br/>━━━━━━━━━━━━━━━<br/>🟩 每个方法 = 一个栈帧<br/>🟩 局部变量、操作数栈<br/>━━━━━━━━━━━━━━━<br/>⚠️ StackOverflowError"]
        
        NS["本地方法栈 Native Stack<br/>━━━━━━━━━━━━━━━<br/>🟨 native 方法使用<br/>━━━━━━━━━━━━━━━<br/>⚠️ StackOverflowError"]
        
        PC["程序计数器 PC Register<br/>━━━━━━━━━━━━━━━<br/>🟪 当前线程执行的<br/>🟪 字节码行号<br/>━━━━━━━━━━━━━━━<br/>✅ 唯一不会 OOM"]
    end
    
    style HEAP fill:#ffcdd2
    style MA fill:#bbdefb
    style VS fill:#c8e6c9
    style NS fill:#fff9c4
    style PC fill:#e1bee7
```

### 一句话记忆

| 区域 | 线程 | 存什么 | 异常 |
|------|------|--------|------|
| **程序计数器** | 私有 | 当前字节码行号 | **无**（唯一不会 OOM） |
| **虚拟机栈** | 私有 | 栈帧（方法调用） | StackOverflowError / OOM |
| **本地方法栈** | 私有 | native 方法 | StackOverflowError / OOM |
| **堆** | **共享** | 对象实例、数组 | OutOfMemoryError |
| **方法区** | **共享** | 类信息、常量池、静态变量 | OutOfMemoryError |

---

## 程序计数器（PC Register）

```mermaid
graph LR
    subgraph 线程1
        PC1["PC = 0x003A<br/>（正在执行第15行字节码）"]
    end
    subgraph 线程2
        PC2["PC = 0x0052<br/>（正在执行第28行字节码）"]
    end
    subgraph 线程3
        PC3["PC = undefined<br/>（执行 native 方法）"]
    end
```

- 每个线程一个 PC，互不影响
- 执行 Java 方法时，记录**字节码指令地址**
- 执行 native 方法时，值为 **undefined**
- **唯一不会内存溢出**的区域

> [!tip] 为什么需要 PC？
> 线程切换后需要恢复到正确的执行位置。PC 就是记录"执行到哪里了"。

---

## 虚拟机栈（VM Stack）

每个线程一个栈，每调用一个方法就压入一个**栈帧**。

### 栈帧结构

```mermaid
graph TB
    subgraph 虚拟机栈["线程的虚拟机栈"]
        direction TB
        F3["栈帧3: methodC()<br/>（栈顶 = 当前方法）"]
        F2["栈帧2: methodB()"]
        F1["栈帧1: main()"]
    end
    
    F3 --> F3D
    
    subgraph F3D["栈帧的内部结构"]
        LV["局部变量表<br/>Local Variables<br/>━━━━━━━━━━<br/>this, 参数, 局部变量<br/>基本类型直接存值<br/>引用类型存指针"]
        OS["操作数栈<br/>Operand Stack<br/>━━━━━━━━━━<br/>计算的临时工作区<br/>如: a + b 的中间结果"]
        DL["动态链接<br/>Dynamic Linking<br/>━━━━━━━━━━<br/>指向方法区中<br/>该方法的引用"]
        RA["返回地址<br/>Return Address<br/>━━━━━━━━━━<br/>方法返回后<br/>继续执行的位置"]
    end
```

### 方法调用过程（图解）

```java
public static void main(String[] args) {
    int result = add(1, 2);
}

public static int add(int a, int b) {
    int sum = a + b;
    return sum;
}
```

```mermaid
sequenceDiagram
    participant S as 虚拟机栈

    Note over S: 1. 调用 main()
    S->>S: 压入 main() 栈帧
    
    Note over S: 2. main 中调用 add(1,2)
    S->>S: 压入 add() 栈帧
    
    Note over S: add() 栈帧内部：
    Note over S: 局部变量表: [a=1, b=2, sum=3]
    Note over S: 操作数栈: push 1, push 2, iadd → 3
    
    Note over S: 3. add() 执行完 return
    S->>S: 弹出 add() 栈帧
    Note over S: 返回值 3 压入 main() 的操作数栈
    
    Note over S: 4. main() 结束
    S->>S: 弹出 main() 栈帧
```

### 操作数栈运算过程

`int c = a + b` 在操作数栈中的执行：

```
步骤1: iload_1 (加载 a=1)     步骤2: iload_2 (加载 b=2)
┌─────┐                       ┌─────┐
│     │                       │  2  │ ← 栈顶
│     │                       ├─────┤
│  1  │ ← 栈顶                │  1  │
└─────┘                       └─────┘

步骤3: iadd (弹出两个,相加)    步骤4: istore_3 (存入 c)
┌─────┐                       ┌─────┐
│     │                       │     │
│     │                       │     │
│  3  │ ← 结果压栈             │     │ ← 弹出存入局部变量表 c=3
└─────┘                       └─────┘
```

### 栈溢出

```java
// StackOverflowError - 递归没有终止条件
public void recursive() {
    recursive();  // 无限压栈帧 → 栈溢出！
}
```

```
-Xss256k    // 设置每个线程的栈大小（默认 1MB 或 512KB，取决于系统）
```

---

## 堆（Heap）

**JVM 最大的内存区域**，也是 GC 的主战场。

### 堆的分代结构

```mermaid
graph TB
    subgraph HEAP["堆 Heap"]
        subgraph YOUNG["新生代 Young Generation (1/3)"]
            EDEN["Eden 区<br/>(8/10)"]
            S0["S0 (From)<br/>(1/10)"]
            S1["S1 (To)<br/>(1/10)"]
        end
        
        subgraph OLD["老年代 Old Generation (2/3)"]
            OD["存放长期存活的对象<br/>大对象直接进入"]
        end
    end
    
    style EDEN fill:#c8e6c9
    style S0 fill:#fff9c4
    style S1 fill:#fff9c4
    style OD fill:#ffcdd2
```

### 默认比例

```
堆总大小
├── 新生代（Young）= 1/3
│   ├── Eden = 8/10
│   ├── Survivor 0 (From) = 1/10
│   └── Survivor 1 (To) = 1/10
└── 老年代（Old）= 2/3

JVM 参数：
-Xms256m        堆初始大小
-Xmx512m        堆最大大小（建议 Xms == Xmx，避免动态扩缩）
-Xmn128m        新生代大小
-XX:NewRatio=2  老年代:新生代 = 2:1
-XX:SurvivorRatio=8  Eden:S0:S1 = 8:1:1
```

### 对象在堆中的流转过程

```mermaid
graph TD
    A["new 对象"] --> B["分配到 Eden 区"]
    B --> C{"Eden 满了？"}
    C -->|"是"| D["触发 Minor GC"]
    D --> E["存活对象复制到 S0<br/>年龄 +1"]
    E --> F["清空 Eden"]
    
    F --> G{"下一次 Eden 又满了"}
    G --> H["Minor GC"]
    H --> I["Eden + S0 存活对象<br/>复制到 S1，年龄 +1"]
    I --> J["清空 Eden + S0"]
    J --> K["S0 和 S1 角色互换"]
    
    K --> L{"对象年龄 ≥ 15？"}
    L -->|"是"| M["晋升到老年代"]
    L -->|"否"| G
    
    N["大对象"] -->|"直接分配"| M
    
    O{"老年代也满了？"} -->|"是"| P["触发 Full GC 💥"]
    M --> O
    
    style P fill:#ffcdd2
    style M fill:#ffcdd2
```

> [!important] 关键数字：15
> 默认对象年龄阈值 = **15**（`-XX:MaxTenuringThreshold=15`）
> 每经过一次 Minor GC 且存活，年龄 +1，达到 15 晋升老年代。
> CMS 默认是 6，G1 默认也是 15。

### 动态年龄判断

不一定非要等到 15 岁！

```
如果 Survivor 区中，年龄 1 + 年龄 2 + ... + 年龄 N 的对象总大小
超过 Survivor 区的 50%（-XX:TargetSurvivorRatio=50）
则年龄 ≥ N 的对象直接晋升老年代

Survivor区是年轻代的一部分，存放 Minor GC 后依然存活的对象。通常有两个（S0/S1），交替使用。

```


1. GC 将 Eden + 存活对象复制到 Survivor 区，并计算每个年龄段的对象总大小。
2. 从 **年龄=1** 开始累加大小：
    - 累加到年龄 `N` 时，检查：`年龄1~N的对象总大小 > Survivor区总容量 × 50%` ？
3. **如果超过**：
    - 本次 GC 的**实际晋升阈值**动态设为 `N`
    - 所有 `年龄 ≥ N` 的对象直接晋升老年代
    - 剩余 `年龄 < N` 的对象留在 Survivor 区，保证 Survivor 使用率 ≈ 50%
4. **如果一直没超过**：
	- 晋升阈值保持默认值（或 `-XX:MaxTenuringThreshold`），对象继续留在年轻代长大
	  
### 大对象直接进老年代

```java
// 大于此阈值的对象直接在老年代分配
-XX:PretenureSizeThreshold=1048576  // 1MB

// 为什么？避免大对象在 Eden 和 Survivor 之间来回复制
```

---

## 方法区（Method Area）

### 不同 JDK 版本的实现

```mermaid
graph TD
    subgraph JDK7及之前["JDK 7 及之前"]
        A["方法区 = 永久代（PermGen）"]
        A --> A1["类信息"]
        A --> A2["常量池"]
        A --> A3["静态变量"]
        A --> A4["JIT 代码"]
        A5["-XX:PermSize / -XX:MaxPermSize"]
    end
    
    subgraph JDK8及之后["JDK 8 及之后"]
        B["方法区 = 元空间（Metaspace）"]
        B --> B1["类信息"]
        B --> B2["运行时常量池"]
        B3["静态变量 → 移到堆中"]
        B4["字符串常量池 → 移到堆中"]
        B5["-XX:MetaspaceSize / -XX:MaxMetaspaceSize"]
        B6["使用本地内存（不再受堆大小限制）"]
    end
    
    JDK7及之前 -->|"JDK 8 变化"| JDK8及之后
    
    style A fill:#ffcdd2
    style B fill:#a5d6a7
```

> [!warning] 面试重点
> - JDK 7：方法区 = **永久代**（PermGen），在 JVM 堆内
> - JDK 8：方法区 = **元空间**（Metaspace），使用**本地内存**（Native Memory）
> - 字符串常量池：JDK 7 从永久代移到**堆**中
> - 静态变量：JDK 8 从永久代移到**堆**中

### 为什么废弃永久代？

1. 永久代大小固定，难以调优，容易 OOM
2. 元空间使用本地内存，可以自动扩展
3. 为 JRockit 和 HotSpot 合并铺路（JRockit 没有永久代）

### 字符串常量池

```java
String s1 = "hello";         // 字面量 → 字符串常量池
String s2 = "hello";         // 直接引用常量池中已有的
String s3 = new String("hello"); // 堆中新建对象

System.out.println(s1 == s2); // true（同一个引用）
System.out.println(s1 == s3); // false（不同对象）

String s4 = s3.intern();     // intern() → 返回常量池中的引用
System.out.println(s1 == s4); // true
```

```mermaid
graph TD
    subgraph 堆
        SCP["字符串常量池<br/>'hello' (地址: 0x100)"]
        OBJ["new String('hello')<br/>(地址: 0x200)"]
    end
    
    subgraph 栈
        S1["s1 → 0x100"]
        S2["s2 → 0x100"]
        S3["s3 → 0x200"]
        S4["s4 → 0x100（intern）"]
    end
    
    S1 --> SCP
    S2 --> SCP
    S3 --> OBJ
    S4 --> SCP
    OBJ -.->|"内部 char[]"| SCP
```

---

## 直接内存（Direct Memory）

不属于 JVM 运行时数据区，但经常被问到。

```mermaid
graph LR
    subgraph JVM
        A["Java 堆"]
        B["DirectByteBuffer 对象<br/>（引用直接内存）"]
    end
    
    subgraph 本地内存
        C["直接内存<br/>（Native Memory）"]
    end
    
    B --> C
    
    style C fill:#e1bee7
```

- 通过 `ByteBuffer.allocateDirect()` 分配
- NIO 使用，避免了堆内存和本地内存之间的数据拷贝
- 不受 `-Xmx` 限制，但受 `-XX:MaxDirectMemorySize` 限制
- 也可能导致 OOM

---

## 栈 vs 堆 对比

```mermaid
graph TD
    subgraph 栈["栈（Stack）"]
        S1["线程私有"]
        S2["存储方法调用、局部变量"]
        S3["自动分配释放"]
        S4["速度快"]
        S5["空间小（~1MB/线程）"]
        S6["LIFO 后进先出"]
    end
    
    
```
```mermaid
graph TD
    subgraph 堆["堆（Heap）"]
        H1["线程共享"]
        H2["存储对象实例"]
        H3["GC 管理"]
        H4["速度较慢"]
        H5["空间大（可达几GB）"]
        H6["无序"]
    end
    
    
```
```java
public void example() {
    int a = 10;              // 栈：基本类型值直接存在栈帧的局部变量表
    String name = "hello";   // 栈：引用存在栈，字符串在堆的常量池
    Object obj = new Object(); // 栈：引用存在栈，对象在堆
}
```

```mermaid
graph LR
    subgraph 栈帧
        A["a = 10（值）"]
        B["name = 0x100（引用）"]
        C["obj = 0x200（引用）"]
    end
    
    subgraph 堆
        D["'hello'（常量池）"]
        E["Object 实例"]
    end
    
    B --> D
    C --> E
```

---

## 面试高频问题

### Q1：JVM 运行时数据区有哪些？

5 个区域：程序计数器、虚拟机栈、本地方法栈（线程私有），堆、方法区（线程共享）。

### Q2：堆和栈的区别？

栈是线程私有的、存方法调用和局部变量、自动管理；堆是线程共享的、存对象实例、由 GC 管理。

### Q3：方法区在 JDK 7 和 JDK 8 有什么变化？

JDK 7 方法区由永久代实现（堆内），JDK 8 改为元空间（本地内存）。字符串常量池在 JDK 7 移到堆中，静态变量在 JDK 8 移到堆中。

### Q4：什么情况下会栈溢出？

递归调用没有终止条件导致无限压栈帧；线程请求的栈深度超过 `-Xss` 设定的大小。

### Q5：堆为什么要分代？

不同对象的生命周期不同。**大部分对象朝生夕灭**（IBM 研究：98% 的对象在新生代就会被回收），分代后可以针对性使用不同的 GC 算法：新生代用复制算法（高效），老年代用标记-整理（节约空间）。
