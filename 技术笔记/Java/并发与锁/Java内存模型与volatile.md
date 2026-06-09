---
title: Java内存模型与volatile
tags:
  - Java
  - JMM
  - volatile
  - 内存屏障
  - 面试
created: 2026-04-07
up: "[[Java并发与锁底层原理 - 总览]]"
---

# Java 内存模型与 volatile

JMM 是理解一切并发问题的**基石**，不理解 JMM 就无法理解锁。

## Java 内存模型（JMM）

### 为什么需要 JMM？

```mermaid
graph TD
    A["问题根源"] --> B["CPU 有多级缓存<br/>每个核心有自己的 L1/L2 Cache"]
    A --> C["编译器和 CPU 会重排序指令<br/>（优化性能）"]
    A --> D["多线程读写共享变量<br/>可能看到过期值"]
    
    B & C & D --> E["💥 可见性、有序性、原子性问题"]
    E --> F["JMM 定义规则<br/>约束多线程如何访问共享内存"]
    
    style E fill:#ffcdd2
    style F fill:#a5d6a7
```

### JMM 内存结构

```mermaid
graph TD
    subgraph 线程1
        WM1["工作内存<br/>（CPU 缓存/寄存器）<br/>变量副本: x=0"]
    end
    
    subgraph 线程2
        WM2["工作内存<br/>（CPU 缓存/寄存器）<br/>变量副本: x=0"]
    end
    
    subgraph 主内存["主内存（所有线程共享）"]
        MM["共享变量: x=1"]
    end
    
    WM1 <-->|"read/write"| MM
    WM2 <-->|"read/write"| MM
    
    WM1 -.->|"❌ 不能直接访问"| WM2
```

> [!important] 核心规则
> 1. 所有共享变量存在**主内存**中
> 2. 每个线程有自己的**工作内存**（本地缓存）
> 3. 线程对变量的操作必须在工作内存中进行
> 4. 线程之间**不能直接访问**对方的工作内存
> 5. 线程间通信必须通过主内存**传递**

### 并发三大问题

```mermaid
graph TD
    A["并发三大问题"]
    
    A --> B["可见性<br/>Visibility"]
    B --> B1["线程A修改了x<br/>线程B看不到最新值"]
    B --> B2["✅ volatile / synchronized / Lock"]
    
    A --> C["原子性<br/>Atomicity"]
    C --> C1["i++ 不是原子操作<br/>（读-改-写三步）"]
    C --> C2["✅ synchronized / Lock / Atomic类"]
    
    A --> D["有序性<br/>Ordering"]
    D --> D1["编译器/CPU 重排序<br/>导致执行顺序与代码不一致"]
    D --> D2["✅ volatile / synchronized / happens-before"]
```

### i++ 为什么不是原子操作？

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant T2 as 线程2
    participant M as 主内存 i=0

    T1->>M: 读取 i=0
    T2->>M: 读取 i=0
    T1->>T1: i+1=1
    T2->>T2: i+1=1
    T1->>M: 写回 i=1
    T2->>M: 写回 i=1
    
    Note over M: 期望 i=2，实际 i=1 ❌
```

```
i++ 的字节码（三步操作）:
1. iload    → 从工作内存读取 i 的值
2. iadd     → 加 1
3. istore   → 写回工作内存

三步之间可以被其他线程打断 → 不是原子操作
```

---

## happens-before 规则

JMM 不是说完全禁止重排序，而是通过 **happens-before** 规则约束哪些操作的结果对其他线程可见。

> **如果 A happens-before B，则 A 的操作结果对 B 可见，且 A 在 B 之前执行。**

### 8 大 happens-before 规则

```mermaid
graph TD
    A["happens-before 8 大规则"]
    
    A --> B["1. 程序顺序规则<br/>同一线程中，前面的操作<br/>happens-before 后面的"]
    
    A --> C["2. volatile 规则<br/>volatile 写 happens-before<br/>后续的 volatile 读"]
    
    A --> D["3. 锁规则<br/>unlock happens-before<br/>后续的 lock"]
    
    A --> E["4. 线程启动规则<br/>start() happens-before<br/>子线程的任何操作"]
    
    A --> F["5. 线程终止规则<br/>线程所有操作<br/>happens-before join()返回"]
    
    A --> G["6. 中断规则<br/>interrupt() happens-before<br/>检测到中断"]
    
    A --> H["7. 终结器规则<br/>构造函数 happens-before<br/>finalize()"]
    
    A --> I["8. 传递性<br/>A hb B, B hb C<br/>→ A hb C"]
```

### 可见性问题示例

```java
// 没有 volatile → 可能死循环！
boolean running = true;  // 共享变量

// 线程1
new Thread(() -> {
    while (running) {  // 可能永远读到 true（工作内存的缓存值）
        // do something
    }
}).start();

// 线程2
running = false;  // 线程2修改了，但线程1可能看不到
```

```mermaid
graph TD
    subgraph 线程1工作内存
        A["running = true<br/>（缓存的旧值，永远不刷新）"]
    end
    
    subgraph 线程2工作内存
        B["running = false<br/>（修改后可能没同步到主内存）"]
    end
    
    subgraph 主内存
        C["running = false"]
    end
    
    B -->|"写回"| C
    C -.->|"❌ 线程1不知道要重新读"| A
    
    style A fill:#ffcdd2
```

---

## volatile 底层原理

### volatile 的两大作用

```mermaid
graph TD
    A["volatile"]
    A --> B["1. 保证可见性<br/>修改后立即刷新到主内存<br/>读取时从主内存获取最新值"]
    A --> C["2. 禁止指令重排序<br/>通过内存屏障实现"]
    A --> D["❌ 不保证原子性<br/>volatile i++ 仍然有问题"]
    
    style B fill:#a5d6a7
    style C fill:#a5d6a7
    style D fill:#ffcdd2
```

### volatile 可见性原理

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant M as 主内存
    participant T2 as 线程2

    Note over M: volatile int x = 0
    
    T1->>T1: x = 1（写 volatile）
    T1->>M: ① 强制刷新到主内存
    Note over M: x = 1
    M->>T2: ② 线程2的缓存失效
    T2->>M: ③ 从主内存重新读取
    T2->>T2: 读到 x = 1 ✅
```

**底层实现（x86）：**
- volatile 写 → 生成 `lock` 前缀指令
- `lock` 指令做两件事：
  1. 将当前处理器缓存行写回主内存
  2. 使其他 CPU 的缓存行**失效**（MESI 缓存一致性协议）

### 内存屏障（Memory Barrier）

volatile 通过插入**内存屏障**禁止重排序：

```mermaid
graph TD
    subgraph volatile写
        A["普通读/写"]
        B["═══ StoreStore 屏障 ═══<br/>禁止上方普通写和下方volatile写重排"]
        C["volatile 写"]
        D["═══ StoreLoad 屏障 ═══<br/>禁止volatile写和下方volatile读重排"]
        A --> B --> C --> D
    end
    
    subgraph volatile读
        E["volatile 读"]
        F["═══ LoadLoad 屏障 ═══<br/>禁止volatile读和下方普通读重排"]
        G["═══ LoadStore 屏障 ═══<br/>禁止volatile读和下方普通写重排"]
        H["普通读/写"]
        E --> F --> G --> H
    end
```

### 四种内存屏障

| 屏障类型 | 说明 |
|----------|------|
| **LoadLoad** | Load1; LoadLoad; Load2 → Load1 在 Load2 之前完成 |
| **StoreStore** | Store1; StoreStore; Store2 → Store1 在 Store2 之前刷新到主内存 |
| **LoadStore** | Load1; LoadStore; Store2 → Load1 在 Store2 之前完成 |
| **StoreLoad** | Store1; StoreLoad; Load2 → Store1 刷新到主内存后才能执行 Load2（**最强屏障**） |

### volatile 经典应用：双重检查锁单例

```java
public class Singleton {
    private static volatile Singleton instance;  // 必须 volatile！
    
    public static Singleton getInstance() {
        if (instance == null) {              // 第一次检查（无锁）
            synchronized (Singleton.class) {
                if (instance == null) {      // 第二次检查（有锁）
                    instance = new Singleton(); // 这一行可能被重排序！
                }
            }
        }
        return instance;
    }
}
```

**为什么需要 volatile？**

```mermaid
graph TD
    A["instance = new Singleton() 的三步操作"]
    A --> B["1. 分配内存空间"]
    A --> C["2. 初始化对象"]
    A --> D["3. 将引用指向内存"]
    
    E["JVM 可能重排序为 1→3→2！"]
    E --> F["线程A 执行了 1→3（还没初始化）"]
    F --> G["线程B 第一次检查 instance != null"]
    G --> H["线程B 拿到一个<br/>未初始化的对象 💥"]
    
    I["加 volatile 禁止 2 和 3 的重排序 ✅"]
    
    style H fill:#ffcdd2
    style I fill:#a5d6a7
```

---

## synchronized vs volatile 对比

| 特性 | synchronized | volatile |
|------|-------------|----------|
| **可见性** | ✅ | ✅ |
| **原子性** | ✅ | ❌ |
| **有序性** | ✅ | ✅ |
| **阻塞** | 会阻塞 | 不阻塞 |
| **使用范围** | 方法/代码块 | 变量 |
| **性能** | 较重 | 较轻 |
| **适用场景** | 复合操作 | 状态标志、DCL 单例 |

---

## 面试高频问题

### Q1：JMM 是什么？

Java 内存模型定义了多线程如何访问共享内存的规则。每个线程有自己的工作内存（缓存），共享变量在主内存中。JMM 通过 happens-before 规则约束可见性和有序性。

### Q2：volatile 能保证什么？不能保证什么？

能保证**可见性**（修改立即对其他线程可见）和**有序性**（禁止重排序）。不能保证**原子性**（volatile i++ 仍然有问题）。

### Q3：volatile 底层怎么实现的？

写操作生成 `lock` 前缀指令，将缓存行写回主内存并使其他 CPU 缓存失效。通过插入**内存屏障**（StoreStore、StoreLoad、LoadLoad、LoadStore）禁止重排序。

### Q4：DCL 单例为什么需要 volatile？

`new Singleton()` 不是原子操作（分配内存→初始化→赋值引用），JVM 可能重排序为分配内存→赋值引用→初始化。其他线程可能拿到未初始化的对象。volatile 禁止这种重排序。
