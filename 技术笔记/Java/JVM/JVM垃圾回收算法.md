---
title: JVM垃圾回收算法
tags:
  - JVM
  - GC
  - 垃圾回收
  - 面试
created: 2026-04-07
up: "[[JVM底层原理 - 总览]]"
---

# JVM 垃圾回收算法

GC 是 JVM 面试的**绝对核心**，必须深入掌握。

## 对象存活判断

### 引用计数法（Reference Counting）

```mermaid
graph TD
    A["对象A<br/>refcount = 1"]
    B["对象B<br/>refcount = 1"]
    
    A -->|"引用"| B
    B -->|"引用"| A
    
    C["💥 循环引用！<br/>refcount 永远不为 0<br/>无法回收"]
    
    style C fill:#ffcdd2
```

- 每个对象维护一个引用计数器
- 被引用 +1，引用失效 -1
- 计数为 0 可回收
- **❌ JVM 不使用！** 无法解决循环引用

### 可达性分析（Reachability Analysis）✅

**JVM 实际使用的算法。**

```mermaid
graph TD
    subgraph GC_Roots["GC Roots"]
        R1["栈中引用的对象"]
        R2["静态变量引用的对象"]
        R3["常量引用的对象"]
        R4["JNI 引用的对象"]
        R5["同步锁持有的对象"]
    end
    
    R1 --> A["对象A ✅"]
    A --> B["对象B ✅"]
    A --> C["对象C ✅"]
    R2 --> D["对象D ✅"]
    
    E["对象E ❌"]
    F["对象F ❌"]
    E --> F
    F --> E
    
    style E fill:#ffcdd2
    style F fill:#ffcdd2
    style A fill:#a5d6a7
    style B fill:#a5d6a7
    style C fill:#a5d6a7
    style D fill:#a5d6a7
```

**核心思想**：从 GC Roots 出发，沿引用链遍历。能到达的对象 = 存活，不可达的对象 = 可回收。

### GC Roots 有哪些？

```mermaid
graph TD
    A["GC Roots"]
    A --> B["1.虚拟机栈中引用的对象<br/>（局部变量表中的引用）"]
    A --> C["2.方法区中静态变量引用的对象<br/>（static 字段）"]
    A --> D["3.方法区中常量引用的对象<br/>（final static 字段）"]
    A --> E["4.本地方法栈中 JNI 引用的对象"]
    A --> F["5.被同步锁 synchronized 持有的对象"]
    A --> G["6.JVM 内部引用<br/>（Class 对象、异常对象、类加载器）"]
```

> [!important] 面试必背
> GC Roots 记忆口诀：**栈引用、静态变量、常量、JNI、锁对象**

### finalize() 拯救机制

```mermaid
graph TD
    A["对象不可达"] --> B{"重写了 finalize()？"}
    B -->|"否"| C["直接回收 💀"]
    B -->|"是"| D{"finalize() 是否已执行过？"}
    D -->|"已执行过"| C
    D -->|"未执行"| E["放入 F-Queue 队列"]
    E --> F["低优先级线程执行 finalize()"]
    F --> G{"finalize() 中重新建立引用？"}
    G -->|"是"| H["对象复活 ✅（仅此一次！）"]
    G -->|"否"| C
    
    style C fill:#ffcdd2
    style H fill:#a5d6a7
```

> [!danger] 不推荐使用 finalize()
> 1. 执行不确定（不保证一定会执行）
> 2. 只能拯救一次
> 3. 性能差
> 4. Java 9+ 已标记为 `@Deprecated`

---

## 四种引用类型

```mermaid
graph TD
    A["Java 四种引用<br/>（由强到弱）"]
    A --> B["强引用 Strong<br/>Object obj = new Object()<br/>GC 绝对不回收"]
    A --> C["软引用 Soft<br/>SoftReference<br/>内存不足时回收"]
    A --> D["弱引用 Weak<br/>WeakReference<br/>下次 GC 就回收"]
    A --> E["虚引用 Phantom<br/>PhantomReference<br/>随时回收，用于跟踪GC"]
    
    style B fill:#ffcdd2
    style C fill:#ffcc80
    style D fill:#fff9c4
    style E fill:#e0e0e0
```

| 引用类型 | 回收时机 | 用途 |
|----------|----------|------|
| **强引用** | 永不回收（只要可达） | 普通引用 |
| **软引用** | 内存不足时回收 | **缓存**（内存敏感的缓存） |
| **弱引用** | 下次 GC 一定回收 | **ThreadLocalMap**、WeakHashMap |
| **虚引用** | 随时回收 | 跟踪对象被 GC 的时机（NIO DirectBuffer 回收） |

```java
// 软引用
SoftReference<byte[]> cache = new SoftReference<>(new byte[1024 * 1024]);
cache.get(); // 内存足够返回对象，内存不足返回 null

// 弱引用
WeakReference<Object> weak = new WeakReference<>(new Object());
weak.get(); // 下次 GC 前可以获取，GC 后返回 null
```

---

## 三大垃圾回收算法

### 1. 标记-清除（Mark-Sweep）

```mermaid
graph TD
    subgraph 标记前["标记前"]
        A1["A ✅"] --- B1["B ❌"] --- C1["C ✅"] --- D1["D ❌"] --- E1["E ✅"]
    end
    
    subgraph 标记后清除["标记-清除后"]
        A2["A"] --- B2["空闲"] --- C2["C"] --- D2["空闲"] --- E2["E"]
    end
    
    标记前 -->|"标记不可达对象<br/>然后清除"| 标记后清除
```

```
标记阶段: 从 GC Roots 遍历，标记所有存活对象
清除阶段: 遍历堆，回收未标记的对象

✅ 优点: 实现简单
❌ 缺点: 
  1. 效率不高（两次遍历）
  2. 产生大量内存碎片！
```

### 2. 标记-复制（Copying）

```mermaid
graph TD
    subgraph 复制前["复制前"]
        direction LR
        subgraph FROM["From 区"]
            A1["A ✅"]
            B1["B ❌"]
            C1["C ✅"]
            D1["D ❌"]
        end
        subgraph TO["To 区（空的）"]
            EMPTY["空"]
        end
    end
    
    subgraph 复制后["复制后"]
        direction LR
        subgraph FROM2["From 区（清空）"]
            EMPTY2["空"]
        end
        subgraph TO2["To 区"]
            A2["A"]
            C2["C"]
            FREE["空闲（连续）"]
        end
    end
    
    复制前 -->|"将存活对象复制到 To 区<br/>然后清空 From 区"| 复制后
    
    style TO2 fill:#a5d6a7
```

```
将内存分为两块，每次只用一块
GC 时把存活对象复制到另一块
然后清空当前块

✅ 优点:
  1. 没有碎片（复制后连续排列）
  2. 效率高（只需遍历存活对象）
❌ 缺点:
  1. 浪费一半内存空间！
  2. 对象存活率高时复制开销大
```

> [!tip] 新生代使用的就是复制算法
> 但不是 1:1 分区，而是 Eden:S0:S1 = 8:1:1
> 只浪费 10% 空间（一个 Survivor）

### 3. 标记-整理（Mark-Compact）

```mermaid
graph TD
    subgraph 整理前["标记后"]
        A1["A ✅"] --- B1["空"] --- C1["C ✅"] --- D1["空"] --- E1["E ✅"] --- F1["空"]
    end
    
    subgraph 整理后["整理后"]
        A2["A"] --- C2["C"] --- E2["E"] --- FREE["空闲（连续）"]
    end
    
    整理前 -->|"将存活对象向一端移动<br/>清除边界外的内存"| 整理后
    
    style 整理后 fill:#a5d6a7
```

```
标记后不直接清除，而是让存活对象向内存一端移动
然后清理边界以外的内存

✅ 优点: 没有碎片
❌ 缺点: 移动对象成本高（需要更新所有引用）
```

### 三种算法对比

| 算法 | 碎片 | 空间利用率 | 效率 | 适用场景 |
|------|------|-----------|------|----------|
| **标记-清除** | ❌ 有碎片 | 高 | 中等 | CMS 老年代 |
| **标记-复制** | ✅ 无碎片 | 低（浪费一半） | **最高** | **新生代** |
| **标记-整理** | ✅ 无碎片 | 高 | 低（移动） | **老年代** |

---

## 分代收集理论

```mermaid
graph TD
    subgraph 分代收集["分代收集策略"]
        subgraph 新生代["新生代"]
            Y1["特点：对象朝生夕灭<br/>98% 对象在 Minor GC 时死亡"]
            Y2["算法：标记-复制<br/>（Eden:S0:S1 = 8:1:1）"]
            Y3["只需复制少量存活对象<br/>效率极高"]
        end
        
        subgraph 老年代["老年代"]
            O1["特点：对象存活率高<br/>没有额外空间担保"]
            O2["算法：标记-清除 或 标记-整理"]
            O3["存活对象多，复制不划算"]
        end
    end
    
    style Y2 fill:#a5d6a7
    style O2 fill:#ffcc80
```

### 分代假说

| 假说         | 内容                |
| ---------- | ----------------- |
| **弱分代假说**  | 绝大多数对象都是朝生夕灭的     |
| **强分代假说**  | 熬过越多次 GC 的对象越难被回收 |
| **跨代引用假说** | 跨代引用相对于同代引用仅占少数   |

---

## Minor GC vs Major GC vs Full GC

```mermaid
graph TD
    A["GC 类型"]
    A --> B["Minor GC / Young GC<br/>━━━━━━━━━━━━<br/>只收集新生代<br/>频率高、速度快<br/>触发：Eden 区满"]
    A --> C["Major GC / Old GC<br/>━━━━━━━━━━━━<br/>只收集老年代<br/>一般伴随 Minor GC<br/>CMS 单独收集老年代"]
    A --> D["Full GC<br/>━━━━━━━━━━━━<br/>收集整个堆 + 方法区<br/>速度最慢！尽量避免"]
    
    style D fill:#ffcdd2
```

### 触发 Full GC 的条件

```mermaid
graph TD
    A["什么时候触发 Full GC？"]
    A --> B["1.老年代空间不足"]
    A --> C["2.方法区（元空间）不足"]
    A --> D["3.调用 System.gc()（建议，非强制）"]
    A --> E["4.Minor GC 后存活对象放不进老年代<br/>（空间分配担保失败）"]
    A --> F["5.CMS GC 时 concurrent mode failure"]
    
    style A fill:#ffcdd2
```

### 空间分配担保机制

```mermaid
graph TD
    A["Minor GC 前的担保检查"] --> B{"老年代连续空间 ><br/>新生代所有对象总大小？"}
    B -->|"是"| C["安全，执行 Minor GC ✅"]
    B -->|"否"| D{"是否允许担保失败？<br/>HandlePromotionFailure"}
    D -->|"是"| E{"老年代连续空间 ><br/>历次晋升平均大小？"}
    E -->|"是"| F["冒险执行 Minor GC<br/>（可能成功，可能 Full GC）"]
    E -->|"否"| G["直接 Full GC"]
    D -->|"否"| G
    
    style G fill:#ffcdd2
```

---

## 记忆集与写屏障

### 跨代引用问题

```mermaid
graph TD
    subgraph 老年代
        A["对象A"]
    end
    subgraph 新生代
        B["对象B"]
    end
    
    A -->|"跨代引用"| B
    
    C["Minor GC 时<br/>怎么知道对象B被老年代引用？<br/>难道要扫描整个老年代？"]
    
    style C fill:#fff9c4
```

### 记忆集（Remembered Set）

```mermaid
graph TD
    subgraph 老年代
        A["对象A → 引用新生代对象"]
        CARD["卡表(Card Table)<br/>记录哪些区域有跨代引用<br/>━━━━━━━━━━━━<br/>| 0 | 1 | 0 | 0 | 1 |<br/>  ↑ dirty card"]
    end
    
    subgraph 新生代
        B["对象B"]
    end
    
    A -->|"引用"| B
    CARD -->|"Minor GC 只扫描<br/>dirty card 对应的区域"| A
    
    style CARD fill:#fff9c4
```

- **卡表**是记忆集的具体实现
- 将老年代划分为 512 字节一个的 Card
- 有跨代引用的 Card 标记为 dirty
- Minor GC 时只扫描 dirty card → 避免扫描整个老年代

### 写屏障（Write Barrier）

在引用赋值时自动维护卡表：

```java
// 伪代码
void oop_store(oop* field, oop value) {
    *field = value;                    // 实际赋值
    card_table[field >> 9] = dirty;   // 写屏障：更新卡表
}
```

---

## 面试高频问题

### Q1：怎么判断对象可以被回收？

JVM 使用**可达性分析**：从 GC Roots 出发，不可达的对象可回收。GC Roots 包括栈引用、静态变量、常量、JNI 引用、锁对象。

### Q2：垃圾回收算法有哪些？

标记-清除（有碎片）、标记-复制（无碎片但浪费空间）、标记-整理（无碎片但要移动对象）。新生代用复制算法，老年代用标记-清除或标记-整理。

### Q3：什么时候触发 Full GC？

老年代空间不足、元空间不足、空间分配担保失败、CMS 并发失败、System.gc()。

### Q4：为什么新生代用复制算法？

因为新生代对象存活率低（98% 会死），复制算法只需要复制少量存活对象，效率极高。Eden:S0:S1 = 8:1:1 只浪费 10% 空间。
