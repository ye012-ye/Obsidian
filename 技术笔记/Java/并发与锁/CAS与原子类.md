---
title: CAS与原子类
tags:
  - Java
  - CAS
  - 原子类
  - ABA
  - 面试
created: 2026-04-07
up: "[[Java并发与锁底层原理 - 总览]]"
---

# CAS 与原子类

CAS 是**无锁并发**的基础，也是 AQS、原子类、ConcurrentHashMap 等一切并发工具的底层支撑。

## CAS 原理

### 什么是 CAS？

**Compare And Swap**（比较并交换），一条 CPU 原子指令。

```mermaid
graph TD
    A["CAS(内存地址V, 预期值A, 新值B)"]
    A --> B{"内存中的值 == 预期值A？"}
    B -->|"是"| C["将内存值更新为B ✅<br/>返回 true"]
    B -->|"否"| D["不做任何操作 ❌<br/>返回 false"]
    
    E["整个过程是 CPU 级别的原子操作<br/>不会被中断！"]
    
    style C fill:#a5d6a7
    style D fill:#ffcdd2
    style E fill:#fff9c4
```

### CAS 执行过程

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant T2 as 线程2
    participant M as 内存 V=10

    T1->>M: 读取 V=10（预期值A=10）
    T2->>M: 读取 V=10（预期值A=10）
    
    T1->>M: CAS(V, 10, 11)
    Note over M: V==10? 是! → V=11 ✅
    
    T2->>M: CAS(V, 10, 11)
    Note over M: V==10? 否(V=11)! → 失败 ❌
    T2->>T2: 重新读取 V=11，再次 CAS
    T2->>M: CAS(V, 11, 12)
    Note over M: V==11? 是! → V=12 ✅
```

### CAS 底层实现

```mermaid
graph TD
    A["Java: Unsafe.compareAndSwapInt()"]
    A --> B["JNI 调用 C++ 代码"]
    B --> C["x86 CPU 指令:<br/>lock cmpxchg"]
    
    C --> D["lock 前缀：锁定总线/缓存行<br/>cmpxchg：比较并交换<br/>整个操作是原子的"]
    
    style C fill:#e1bee7
```

```java
// Unsafe 类中的 CAS 方法（native 方法）
public final native boolean compareAndSwapInt(
    Object obj,    // 对象
    long offset,   // 字段内存偏移量
    int expected,  // 预期值
    int update     // 新值
);
```

---

## CAS 的三大问题

```mermaid
graph TD
    A["CAS 的问题"]
    A --> B["1. ABA 问题"]
    A --> C["2. 自旋开销大<br/>长时间 CAS 失败→CPU 空转"]
    A --> D["3. 只能保证一个变量的原子性<br/>多变量需要锁或 AtomicReference"]
```

### ABA 问题

```mermaid
sequenceDiagram
    participant T1 as 线程1
    participant T2 as 线程2
    participant M as 内存 V=A

    T1->>M: 读取 V = A
    Note over T1: 线程1被挂起...
    
    T2->>M: CAS(A → B) ✅
    Note over M: V = B
    T2->>M: CAS(B → A) ✅
    Note over M: V = A（又变回来了！）
    
    T1->>M: CAS(A → C)
    Note over M: V==A? 是! → V=C ✅
    Note over T1: 线程1不知道 V 被改过！💥
```

```
看起来值没变（还是A），实际上已经被修改了两次。
在某些场景下（如链表/栈操作），这可能导致严重问题。
```

### ABA 解决方案

```mermaid
graph TD
    A["ABA 解决方案"]
    A --> B["AtomicStampedReference<br/>加版本号（stamp）"]
    A --> C["AtomicMarkableReference<br/>加布尔标记（mark）"]
    
    B --> B1["CAS 时不仅比较值<br/>还比较版本号<br/>A(v1) → B(v2) → A(v3)<br/>版本号不同 → CAS 失败 ✅"]
```

```java
// AtomicStampedReference 解决 ABA
AtomicStampedReference<Integer> ref = 
    new AtomicStampedReference<>(100, 1); // 初始值100, 版本号1

int stamp = ref.getStamp();       // 获取当前版本号
int value = ref.getReference();   // 获取当前值

// CAS 时同时比较值和版本号
ref.compareAndSet(
    100,     // 预期值
    200,     // 新值
    stamp,   // 预期版本号
    stamp + 1 // 新版本号
);
```

---

## 原子类

### 原子类家族

```mermaid
graph TD
    A["Java 原子类"]
    A --> B["基本类型<br/>AtomicInteger<br/>AtomicLong<br/>AtomicBoolean"]
    A --> C["引用类型<br/>AtomicReference<br/>AtomicStampedReference<br/>AtomicMarkableReference"]
    A --> D["数组类型<br/>AtomicIntegerArray<br/>AtomicLongArray<br/>AtomicReferenceArray"]
    A --> E["字段更新器<br/>AtomicIntegerFieldUpdater<br/>AtomicLongFieldUpdater<br/>AtomicReferenceFieldUpdater"]
    A --> F["JDK 8 累加器<br/>LongAdder ⭐<br/>LongAccumulator<br/>DoubleAdder"]
    
    style F fill:#a5d6a7
```

### AtomicInteger 源码分析

```java
public class AtomicInteger {
    // volatile 保证可见性
    private volatile int value;
    
    // Unsafe 实例，提供 CAS 操作
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    // value 字段的内存偏移量
    private static final long valueOffset;
    
    // getAndIncrement（i++的原子版本）
    public final int getAndIncrement() {
        return unsafe.getAndAddInt(this, valueOffset, 1);
    }
}
```

```java
// Unsafe.getAndAddInt 的实现（自旋 CAS）
public final int getAndAddInt(Object obj, long offset, int delta) {
    int v;
    do {
        v = getIntVolatile(obj, offset);  // 读取当前值
    } while (!compareAndSwapInt(obj, offset, v, v + delta)); // CAS 直到成功
    return v;
}
```

```mermaid
graph TD
    A["getAndIncrement()"] --> B["读取当前值 v"]
    B --> C["CAS(v, v+1)"]
    C --> D{"成功？"}
    D -->|"是"| E["返回旧值 v ✅"]
    D -->|"否"| B
    
    style E fill:#a5d6a7
```

---

## LongAdder（JDK 8 重点）

### AtomicLong 的问题

```mermaid
graph TD
    A["AtomicLong 高并发问题"]
    A --> B["多线程同时 CAS 同一个 value"]
    B --> C["大量线程 CAS 失败 → 不断自旋重试"]
    C --> D["CPU 空转，性能急剧下降"]
    
    style D fill:#ffcdd2
```

### LongAdder 分段思想

```mermaid
graph TD
    subgraph AtomicLong["AtomicLong（单点竞争）"]
        AV["value = 100"]
        T1A["线程1"] --> AV
        T2A["线程2"] --> AV
        T3A["线程3"] --> AV
        T4A["线程4"] --> AV
    end
    
    subgraph LongAdder["LongAdder（分段竞争）"]
        BASE["base = 40"]
        C1["Cell[0] = 20"]
        C2["Cell[1] = 15"]
        C3["Cell[2] = 25"]
        
        T1B["线程1"] --> BASE
        T2B["线程2"] --> C1
        T3B["线程3"] --> C2
        T4B["线程4"] --> C3
        
        SUM["sum() = base + Cell[0] + Cell[1] + Cell[2]<br/>= 40 + 20 + 15 + 25 = 100"]
    end
    
    style AV fill:#ffcdd2
    style LongAdder fill:#a5d6a7
```

### LongAdder 工作流程

```mermaid
graph TD
    A["add(1)"] --> B{"CAS 更新 base 成功？"}
    B -->|"成功"| C["完成 ✅"]
    B -->|"失败（有竞争）"| D{"cells 数组已初始化？"}
    D -->|"否"| E["初始化 cells 数组"]
    D -->|"是"| F["hash 定位到某个 Cell"]
    E --> F
    F --> G{"CAS 更新该 Cell 成功？"}
    G -->|"成功"| C
    G -->|"失败"| H["扩容 cells<br/>或 rehash 换一个 Cell"]
    H --> F
```

### AtomicLong vs LongAdder

| 特性 | AtomicLong | LongAdder |
|------|-----------|-----------|
| **竞争方式** | 所有线程 CAS 同一个值 | 分散到多个 Cell |
| **高并发性能** | 差（大量自旋） | **极好** |
| **精确读取** | 精确 | 最终一致（sum 时可能不精确） |
| **适用场景** | 需要精确值 | **统计计数**（如 QPS） |
| **内存** | 少 | 多（Cell 数组） |

> [!tip] 选择建议
> - 需要精确原子操作（CAS compareAndSet）→ AtomicLong
> - 只需要累加计数（如统计、限流）→ **LongAdder**（性能高数倍）

---

## 面试高频问题

### Q1：CAS 是什么？原理？

Compare And Swap，比较内存值与预期值，相同则更新为新值。底层由 CPU 的 `lock cmpxchg` 指令保证原子性。是乐观锁的实现基础。

### Q2：CAS 有什么问题？怎么解决？

1. **ABA 问题** → AtomicStampedReference（加版本号）
2. **自旋开销** → 自适应自旋、超过阈值升级为锁
3. **只能保证单变量原子性** → AtomicReference 或用锁

### Q3：AtomicInteger 怎么实现的？

内部用 `volatile int value` 保证可见性，通过 `Unsafe.compareAndSwapInt()` 进行 CAS 操作。`getAndIncrement()` 本质是自旋 CAS，直到成功。

### Q4：LongAdder 为什么比 AtomicLong 快？

AtomicLong 所有线程竞争同一个 value，高并发下大量 CAS 失败导致自旋。LongAdder 将值分散到 base + Cell 数组中，不同线程更新不同的 Cell，减少竞争。sum() 时累加所有 Cell 得到总值。
