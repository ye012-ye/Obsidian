---
title: synchronized底层原理
tags:
  - Java
  - synchronized
  - 锁升级
  - Monitor
  - 面试
created: 2026-04-07
up: "[[Java并发与锁底层原理 - 总览]]"
---

# synchronized 底层原理

synchronized 是 Java 并发面试的**绝对 C 位**，锁升级过程必须烂熟于心。

## synchronized 三种用法

```mermaid
graph TD
    A["synchronized 的使用"]
    A --> B["修饰实例方法<br/>锁 = 当前实例对象 this"]
    A --> C["修饰静态方法<br/>锁 = 当前类的 Class 对象"]
    A --> D["修饰代码块<br/>锁 = 括号中指定的对象"]
```

```java
// 1. 修饰实例方法 → 锁 this
public synchronized void method() { }

// 2. 修饰静态方法 → 锁 Class 对象
public static synchronized void method() { }

// 3. 修饰代码块 → 锁指定对象
synchronized (obj) { }
```

---

## 字节码层面

### 同步代码块

```java
synchronized (obj) {
    // 临界区
}
```

```
字节码:
monitorenter      ← 获取锁（monitor 计数器 +1）
  ... 临界区代码 ...
monitorexit        ← 释放锁（monitor 计数器 -1）
monitorexit        ← 异常时也释放（编译器自动添加）
```

### 同步方法

```java
public synchronized void method() { }
```

```
方法的 access_flags 中设置 ACC_SYNCHRONIZED 标志
JVM 在调用方法时自动加锁/解锁
```

---

## Monitor（管程/监视器）

**每一个 Java 对象都可以关联一个 Monitor 对象**（由 C++ 实现的 ObjectMonitor）。

### Monitor 结构

```
ObjectMonitor {
    _header       // Mark Word 备份
    _count        // 重入计数器
    _owner        // 持有锁的线程
    _WaitSet      // wait() 的线程队列
    _EntryList    // 阻塞等待锁的线程队列
    _recursions   // 重入次数
}
```

```mermaid
graph TD
    subgraph Monitor对象
        OWNER["_owner<br/>当前持有锁的线程<br/>Thread-A"]
        
        ENTRY["_EntryList（阻塞队列）<br/>Thread-B<br/>Thread-C<br/>Thread-D"]
        
        WAIT["_WaitSet（等待队列）<br/>Thread-E<br/>Thread-F"]
    end
    
    NEW["新来的线程"] -->|"1. 尝试获取锁"| OWNER
    NEW -->|"2. 获取失败"| ENTRY
    
    OWNER -->|"3. 调用 wait()"| WAIT
    WAIT -->|"4. 被 notify()/notifyAll()"| ENTRY
    ENTRY -->|"5. 竞争获取锁"| OWNER
    OWNER -->|"6. 执行完毕/异常退出"| FREE["释放锁"]
    FREE --> ENTRY
```

### Monitor 工作流程

```mermaid
sequenceDiagram
    participant A as 线程A
    participant M as Monitor
    participant B as 线程B

    A->>M: monitorenter（_owner = A, _count = 1）
    Note over A: 执行同步代码...
    
    B->>M: monitorenter（尝试获取）
    M-->>B: 获取失败 → 进入 _EntryList 阻塞 😴
    
    A->>M: 再次 monitorenter（重入！_count = 2）
    A->>M: monitorexit（_count = 1）
    A->>M: monitorexit（_count = 0, _owner = null）
    
    M->>B: 唤醒 _EntryList 中的线程
    B->>M: 获取锁成功（_owner = B）
```

### wait/notify 流程

```mermaid
graph TD
    A["线程A 持有锁"] -->|"调用 obj.wait()"| B["释放锁<br/>进入 _WaitSet"]
    
    C["线程B 持有锁"] -->|"调用 obj.notify()"| D["从 _WaitSet 取出一个线程<br/>移到 _EntryList"]
    
    D --> E["被唤醒的线程<br/>在 _EntryList 中等待重新获取锁"]
    
    C -->|"释放锁"| F["_EntryList 中的线程竞争获取"]
```

> [!important] wait/notify 必须在 synchronized 块中
> 因为 wait() 需要释放 Monitor 锁，notify() 需要操作 Monitor 的 _WaitSet。没有锁就没有 Monitor → 抛 `IllegalMonitorStateException`。

---

## 对象头与锁状态

synchronized 的锁信息存储在对象头的 **Mark Word** 中（详见 [[JVM对象创建与内存布局#Mark Word 详细结构]]）。

### Mark Word 在不同锁状态下的内容（64位 JVM）

```
┌────────────────────────────────────────────────────────────────┐
│                      Mark Word (64 bits)                        │
├────────────────────────────────┬──────┬────────┬───────────────┤
│           内容                  │ 分代  │ 偏向   │ 锁标志位       │
│                                │ 年龄  │ 锁位   │               │
├────────────────────────────────┼──────┼────────┼───────────────┤
│ 无锁    hashcode(31) unused    │ 4bit │   0    │     01        │
├────────────────────────────────┼──────┼────────┼───────────────┤
│ 偏向锁  threadId(54) epoch(2)  │ 4bit │   1    │     01        │
├────────────────────────────────┼──────┼────────┼───────────────┤
│ 轻量级锁 指向栈中Lock Record指针(62)          │     00        │
├────────────────────────────────┼──────┼────────┼───────────────┤
│ 重量级锁 指向 Monitor 对象的指针(62)           │     10        │
├────────────────────────────────┼──────┼────────┼───────────────┤
│ GC标记   空                                   │     11        │
└────────────────────────────────┴──────┴────────┴───────────────┘
```

---

## 锁升级全流程

这是面试**最高频**的问题，把这张图刻进脑子里：

```mermaid
graph TD
    A["对象刚创建<br/>无锁状态<br/>标志位: 01, 偏向=0"]
    
    A -->|"线程A 第一次获取锁"| B["偏向锁<br/>Mark Word 记录线程A的ID<br/>标志位: 01, 偏向=1"]
    
    B -->|"线程A 再次获取锁<br/>（无需任何同步操作）"| B
    
    B -->|"线程B 尝试获取锁<br/>（出现竞争！）"| C["撤销偏向锁<br/>到达安全点 STW"]
    
    C --> D["轻量级锁<br/>CAS 将 Mark Word 复制到<br/>线程栈的 Lock Record<br/>标志位: 00"]
    
    D -->|"线程B CAS 自旋<br/>尝试获取锁"| D
    
    D -->|"自旋超过阈值<br/>或第三个线程竞争"| E["重量级锁<br/>Mark Word 指向 Monitor<br/>标志位: 10"]
    
    E -->|"未获取锁的线程<br/>进入阻塞（OS层面）"| F["_EntryList 等待"]
    
    style A fill:#e8f5e9
    style B fill:#c8e6c9
    style D fill:#fff9c4
    style E fill:#ffcdd2
```

### 完整流程图（超详细版）

```mermaid
graph TD
    START["synchronized 获取锁"] --> CHECK{"偏向锁是否开启？<br/>-XX:+UseBiasedLocking"}
    
    CHECK -->|"是"| BIAS_CHECK{"Mark Word 的线程ID<br/>是否是当前线程？"}
    CHECK -->|"否"| LIGHT["直接轻量级锁"]
    
    BIAS_CHECK -->|"是（相同线程）"| BIAS_OK["直接执行 ✅<br/>（无需任何同步操作！）"]
    BIAS_CHECK -->|"否（不同线程/无ID）"| BIAS_CAS{"CAS 尝试将<br/>线程ID写入Mark Word"}
    
    BIAS_CAS -->|"成功"| BIAS_OK
    BIAS_CAS -->|"失败（有竞争）"| REVOKE["撤销偏向锁<br/>（等到安全点）"]
    
    REVOKE --> LIGHT["升级为轻量级锁"]
    
    LIGHT --> LR["当前线程栈中创建 Lock Record<br/>复制 Mark Word 到 Lock Record"]
    LR --> LIGHT_CAS{"CAS 将 Mark Word<br/>替换为 Lock Record 指针"}
    
    LIGHT_CAS -->|"成功"| LIGHT_OK["获取轻量级锁 ✅<br/>标志位 = 00"]
    LIGHT_CAS -->|"失败"| SPIN{"自适应自旋"}
    
    SPIN -->|"自旋成功"| LIGHT_OK
    SPIN -->|"自旋失败<br/>（超过阈值）"| HEAVY["膨胀为重量级锁<br/>创建 Monitor 对象<br/>标志位 = 10"]
    
    HEAVY --> BLOCK["未获取锁的线程<br/>进入 Monitor._EntryList<br/>OS 级别阻塞 😴"]
    
    style BIAS_OK fill:#a5d6a7
    style LIGHT_OK fill:#c8e6c9
    style HEAVY fill:#ffcdd2
    style BLOCK fill:#ffcdd2
```

---

## 偏向锁（Biased Locking）

### 核心思想

**大多数情况下，锁不存在多线程竞争，总是同一个线程获取**。偏向锁让这个线程获取锁的成本几乎为零。

```mermaid
sequenceDiagram
    participant A as 线程A
    participant OBJ as 对象 Mark Word

    A->>OBJ: 第一次加锁：CAS 设置 threadId = A
    Note over OBJ: Mark Word: [threadId=A, 偏向=1, 01]
    
    A->>OBJ: 第二次加锁：检查 threadId == A？是！
    Note over A: 直接执行，零开销 ⚡
    
    A->>OBJ: 第三次加锁：检查 threadId == A？是！
    Note over A: 继续零开销 ⚡
```

### 偏向锁撤销

```mermaid
graph TD
    A["线程B 尝试获取锁"]
    A --> B["发现 Mark Word 中 threadId = A（不是自己）"]
    B --> C["等到安全点（STW）"]
    C --> D{"线程A 还在执行<br/>同步代码块内？"}
    D -->|"是"| E["升级为轻量级锁<br/>（A 持有轻量级锁继续执行）"]
    D -->|"否"| F["撤销偏向锁<br/>变为无锁状态"]
    F --> G["线程B 通过轻量级锁竞争"]
    
    style C fill:#ffcdd2
```

> [!warning] JDK 15 默认禁用偏向锁
> `-XX:+UseBiasedLocking`（JDK 15 之前默认开启）
> JDK 15 开始默认关闭偏向锁（认为现代应用竞争普遍，偏向锁撤销的开销反而更大）。

---

## 轻量级锁（Lightweight Lock）

### 核心思想

在**竞争不激烈**时，通过 CAS + 自旋避免操作系统级别的线程阻塞。

### Lock Record 机制

```mermaid
graph TD
    subgraph 线程A栈帧
        LR["Lock Record<br/>━━━━━━━━━━<br/>displaced hdr: Mark Word 副本<br/>owner: → 对象引用"]
    end
    
    subgraph 堆
        OBJ["对象 Mark Word<br/>━━━━━━━━━━<br/>指向 Lock Record 的指针<br/>标志位: 00"]
    end
    
    LR <-->|"CAS 互换"| OBJ
```

```mermaid
sequenceDiagram
    participant A as 线程A
    participant OBJ as 对象
    participant STACK as 线程A 的栈

    A->>STACK: 1. 创建 Lock Record
    A->>STACK: 2. 复制 Mark Word 到 Lock Record（displaced hdr）
    A->>OBJ: 3. CAS 将 Mark Word 替换为 Lock Record 指针
    Note over OBJ: Mark Word → Lock Record 指针 | 00
    
    A->>A: 4. 执行同步代码
    
    A->>OBJ: 5. CAS 将 Mark Word 恢复为 displaced hdr
    Note over A: 如果 CAS 失败 → 有竞争，已膨胀为重量级锁
```

### 自适应自旋（Adaptive Spinning）

```mermaid
graph TD
    A["自旋获取锁"]
    A --> B{"JVM 自适应判断"}
    B -->|"上次自旋成功过"| C["增加自旋次数<br/>（这次可能也会成功）"]
    B -->|"上次自旋失败了"| D["减少自旋次数<br/>甚至直接不自旋"]
    
    C --> E["自旋等待..."]
    E -->|"获取到锁"| F["成功 ✅"]
    E -->|"超过自旋阈值"| G["升级为重量级锁"]
    
    style F fill:#a5d6a7
    style G fill:#ffcdd2
```

> **自适应自旋**：JVM 根据历史数据动态调整自旋次数。比固定自旋更智能。

---

## 重量级锁（Heavyweight Lock）

### 核心：依赖操作系统 Mutex

```mermaid
graph TD
    A["重量级锁"] --> B["Mark Word 指向 Monitor 对象"]
    B --> C["Monitor 由操作系统的<br/>Mutex（互斥量）实现"]
    C --> D["线程阻塞/唤醒需要<br/>用户态 ↔ 内核态切换"]
    D --> E["上下文切换开销大<br/>（约 1-10 微秒）"]
    
    style E fill:#ffcdd2
```

```mermaid
graph LR
    subgraph 用户态
        A["Java 线程代码"]
    end
    
    subgraph 内核态
        B["OS 线程调度<br/>Mutex 操作"]
    end
    
    A -->|"获取/释放锁<br/>阻塞/唤醒线程"| B
    B -->|"返回"| A
    
    C["每次切换 ≈ 数微秒<br/>这就是重量级锁慢的原因"]
    style C fill:#fff9c4
```

---

## 锁升级对比总结

```mermaid
graph LR
    subgraph 无锁
        A["没有竞争"]
    end
    subgraph 偏向锁
        B["只有一个线程<br/>CAS 一次记录线程ID<br/>后续零开销"]
    end
    subgraph 轻量级锁
        C["少量线程交替<br/>CAS + 自旋<br/>不阻塞线程"]
    end
    subgraph 重量级锁
        D["激烈竞争<br/>Monitor + OS Mutex<br/>阻塞线程"]
    end
    
    A -->|"第一个线程"| B
    B -->|"出现竞争"| C
    C -->|"竞争加剧"| D
    
    style A fill:#e8f5e9
    style B fill:#c8e6c9
    style C fill:#fff9c4
    style D fill:#ffcdd2
```

| 锁状态 | 标志位 | 适用场景 | 加锁方式 | 性能 |
|--------|--------|----------|----------|------|
| **无锁** | 01 (偏向=0) | 无竞争 | - | - |
| **偏向锁** | 01 (偏向=1) | 只有一个线程 | CAS 一次 → 后续无操作 | ⚡⚡⚡ |
| **轻量级锁** | 00 | 少量线程交替 | CAS + 自旋 | ⚡⚡ |
| **重量级锁** | 10 | 激烈竞争 | Monitor + OS 阻塞 | ⚡ |

> [!danger] 锁只能升级，不能降级！
> 无锁 → 偏向锁 → 轻量级锁 → 重量级锁，单向不可逆。

---

## 锁优化技术

### JVM 自动优化

```mermaid
graph TD
    A["JVM 锁优化"]
    A --> B["锁消除<br/>JIT 发现锁对象不逃逸<br/>直接去掉 synchronized"]
    A --> C["锁粗化<br/>连续多次加锁同一对象<br/>合并为一次加锁"]
    A --> D["自适应自旋<br/>根据历史动态调整自旋次数"]
    A --> E["偏向锁<br/>消除无竞争时的同步开销"]
```

### 锁消除

```java
// JIT 编译时发现 sb 不逃逸，会自动消除 synchronized
public String concat(String s1, String s2) {
    StringBuffer sb = new StringBuffer(); // sb 是局部变量，不逃逸
    sb.append(s1);  // append 方法内部有 synchronized
    sb.append(s2);  // 但 sb 不会被其他线程访问
    return sb.toString();
}
// 优化后等效于没有 synchronized
```

### 锁粗化

```java
// 原始代码
for (int i = 0; i < 100; i++) {
    synchronized (lock) {
        // do something
    }
}

// JVM 优化后
synchronized (lock) {
    for (int i = 0; i < 100; i++) {
        // do something
    }
}
```

---

## 面试高频问题

### Q1：synchronized 的底层原理？

同步代码块通过 `monitorenter/monitorexit` 字节码指令，底层关联对象的 Monitor（ObjectMonitor）。Monitor 有 _EntryList（阻塞队列）和 _WaitSet（等待队列），通过 _owner 记录持有锁的线程。

### Q2：锁升级过程？

无锁 → 偏向锁（记录线程ID，后续零开销）→ 轻量级锁（CAS + 自旋，不阻塞）→ 重量级锁（Monitor + OS Mutex，阻塞线程）。只能升级不能降级。

### Q3：偏向锁有什么用？为什么 JDK 15 默认关闭了？

偏向锁优化只有一个线程反复获取锁的场景（零开销）。JDK 15 关闭是因为现代应用普遍存在竞争，偏向锁撤销（需要 STW）的开销大于其带来的收益。

### Q4：轻量级锁和重量级锁的区别？

轻量级锁通过 CAS + 自旋在用户态完成，不阻塞线程。重量级锁通过操作系统的 Mutex 实现，需要内核态切换，会阻塞线程。竞争不激烈用轻量级锁，竞争激烈用重量级锁。
