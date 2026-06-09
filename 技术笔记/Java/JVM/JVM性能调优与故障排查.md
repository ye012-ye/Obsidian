---
title: JVM性能调优与故障排查
tags:
  - JVM
  - 调优
  - OOM
  - GC日志
  - 面试
created: 2026-04-07
up: "[[JVM底层原理 - 总览]]"
---

# JVM 性能调优与故障排查

这是面试中**最实战**的部分，面试官喜欢问"你有没有实际调优过JVM"。

## JVM 参数分类

```mermaid
graph TD
    A["JVM 参数"]
    A --> B["标准参数（-）<br/>所有 JVM 都支持<br/>-version, -cp"]
    A --> C["-X 参数<br/>非标准，大部分 JVM 支持<br/>-Xms, -Xmx, -Xss"]
    A --> D["-XX 参数<br/>不稳定，可能变化<br/>-XX:+UseG1GC<br/>-XX:MaxGCPauseMillis=200"]
    
    D --> D1["-XX:+Flag 开启"]
    D --> D2["-XX:-Flag 关闭"]
    D --> D3["-XX:Key=Value 设值"]
```

## 核心 JVM 参数速查

### 内存相关

```mermaid
graph TD
    subgraph JVM内存参数
        XMS["-Xms 堆初始大小<br/>建议等于 Xmx"]
        XMX["-Xmx 堆最大大小<br/>生产 4-8GB 常见"]
        XMN["-Xmn 新生代大小"]
        XSS["-Xss 线程栈大小<br/>默认 1MB"]
        META["-XX:MetaspaceSize 元空间初始<br/>-XX:MaxMetaspaceSize 元空间上限"]
        DIRECT["-XX:MaxDirectMemorySize<br/>直接内存上限"]
    end
```

### 完整参数模板（生产环境参考）

```bash
# 堆内存
-Xms4g -Xmx4g          # 堆大小（初始=最大，避免动态扩缩）
-Xmn2g                  # 新生代 2G（一般为堆的 1/3 ~ 1/2）
-Xss512k                # 线程栈 512KB

# 元空间
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=512m

# 收集器（G1）
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=8m

# GC 日志（JDK 9+）
-Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=100m

# OOM 时 dump 堆
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/tmp/heapdump.hprof
```

---

## OOM 排查实战

### OOM 类型全景

```mermaid
graph TD
    A["OutOfMemoryError"]
    A --> B["Java heap space<br/>堆内存不足"]
    A --> C["Metaspace<br/>元空间不足"]
    A --> D["GC overhead limit exceeded<br/>GC 后回收太少"]
    A --> E["Direct buffer memory<br/>直接内存不足"]
    A --> F["unable to create native thread<br/>线程数超限"]
    
    B --> B1["对象太多/内存泄漏"]
    C --> C1["加载的类太多<br/>（动态代理、CGLIB）"]
    D --> D1["频繁 Full GC<br/>但回收不了多少"]
    E --> E1["NIO DirectBuffer 分配过多"]
    F --> F1["线程数超过 OS 限制"]
```

### 排查流程

```mermaid
graph TD
    A["线上 OOM"] --> B["1. 获取堆转储文件"]
    B --> B1["自动：-XX:+HeapDumpOnOutOfMemoryError"]
    B --> B2["手动：jmap -dump:format=b,file=heap.hprof PID"]
    
    B1 & B2 --> C["2. 分析堆转储"]
    C --> C1["MAT (Memory Analyzer Tool)"]
    C --> C2["VisualVM"]
    C --> C3["JProfiler"]
    
    C1 & C2 & C3 --> D["3. 找到大对象/泄漏链"]
    D --> D1["Dominator Tree：谁占内存最多？"]
    D --> D2["Leak Suspects：可疑泄漏对象"]
    D --> D3["GC Roots 到泄漏对象的引用链"]
    
    D1 & D2 & D3 --> E["4. 定位代码问题"]
    E --> E1["修复内存泄漏"]
    E --> E2["优化对象创建"]
    E --> E3["调整 JVM 参数"]
```

### 常见内存泄漏场景

| 场景 | 原因 | 解决方案 |
|------|------|----------|
| **静态集合** | `static List` 不断 add | 用弱引用或定期清理 |
| **未关闭资源** | Connection、Stream 未 close | try-with-resources |
| **ThreadLocal** | 线程池中 ThreadLocal 未 remove | 用完后 `threadLocal.remove()` |
| **监听器/回调** | 注册后忘记取消注册 | 及时 removeListener |
| **缓存** | 无限增长的缓存 | 使用 LRU 缓存（如 Caffeine） |
| **内部类** | 非静态内部类持有外部类引用 | 改为静态内部类 |

---

## JVM 排查工具

### 命令行工具

```mermaid
graph TD
    A["JVM 命令行工具"]
    A --> B["jps<br/>查看 Java 进程"]
    A --> C["jstat<br/>GC 统计信息"]
    A --> D["jmap<br/>堆信息/dump"]
    A --> E["jstack<br/>线程堆栈"]
    A --> F["jinfo<br/>查看/修改 JVM 参数"]
```

#### jps - 查看进程

```bash
jps -l
# 12345 com.example.Application
```

#### jstat - GC 统计

```bash
# 每 1000ms 输出一次 GC 统计，共 10 次
jstat -gcutil PID 1000 10

#  S0     S1     E      O      M     YGC   YGCT   FGC   FGCT    GCT
#  0.00  52.38  45.67  23.45  96.23  125   0.845   3    0.312   1.157
#  ↑      ↑      ↑      ↑      ↑      ↑     ↑      ↑     ↑       ↑
#  S0使用 S1使用 Eden  Old   Meta  YGC次数 YGC耗时 FGC次数 FGC耗时 总耗时
```

#### jmap - 堆信息

```bash
# 堆使用概况
jmap -heap PID

# 对象统计（按大小排序）
jmap -histo PID | head -20

# 堆转储（线上慎用！会 STW）
jmap -dump:format=b,file=heap.hprof PID
```

#### jstack - 线程堆栈

```bash
# 打印线程堆栈
jstack PID

# 常见用途：
# 1. 排查死锁
# 2. 找到 CPU 高的线程在执行什么
# 3. 排查线程阻塞
```

### CPU 飙高排查流程

```mermaid
graph TD
    A["CPU 100% 报警"] --> B["1. top 找到 CPU 高的进程 PID"]
    B --> C["2. top -Hp PID 找到 CPU 高的线程 TID"]
    C --> D["3. printf '%x' TID 转为十六进制"]
    D --> E["4. jstack PID | grep -A 30 '十六进制TID'"]
    E --> F["5. 查看线程堆栈，定位代码"]
```

```bash
# 实操命令
top                           # 找到 Java 进程 PID=12345
top -Hp 12345                 # 找到 CPU 高的线程 TID=12367
printf '%x\n' 12367           # 转16进制 → 0x304f
jstack 12345 | grep -A 30 '0x304f'  # 查看该线程在干什么
```

### 死锁排查

```bash
jstack PID
# 输出末尾会直接提示：
# Found one Java-level deadlock:
# =============================
# "Thread-1":
#   waiting to lock monitor 0x... (object 0x...)
#   which is held by "Thread-0"
# "Thread-0":
#   waiting to lock monitor 0x... (object 0x...)
#   which is held by "Thread-1"
```

---

## GC 日志分析

### JDK 8 GC 日志格式

```
# 开启 GC 日志
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:gc.log
```

```
Young GC 日志示例:
2026-04-07T10:30:15.123+0800: [GC (Allocation Failure)
  [PSYoungGen: 524288K->43520K(611840K)]  ← 新生代: 回收前→回收后(总大小)
  524288K->43520K(2010112K),              ← 堆: 回收前→回收后(总大小)
  0.0234567 secs]                         ← GC 耗时

Full GC 日志示例:
2026-04-07T10:35:20.456+0800: [Full GC (Metadata GC Threshold)
  [PSYoungGen: 1024K->0K(611840K)]
  [ParOldGen: 410234K->305678K(1398272K)] ← 老年代
  411258K->305678K(2010112K),
  [Metaspace: 256000K->256000K(1298432K)] ← 元空间
  0.5678901 secs]
```

### JDK 9+ 统一日志

```bash
# 输出到文件，5个文件轮转，每个100MB
-Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=100m
```

### GC 日志关注指标

```mermaid
graph TD
    A["GC 日志分析重点"]
    A --> B["Young GC 频率<br/>正常：几秒到几十秒一次"]
    A --> C["Young GC 耗时<br/>正常：< 50ms"]
    A --> D["Full GC 频率<br/>正常：几小时甚至几天一次"]
    A --> E["Full GC 耗时<br/>正常：< 1s"]
    A --> F["GC 后老年代使用率<br/>持续增长 → 内存泄漏！"]
    
    style D fill:#ffcdd2
    style F fill:#ffcdd2
```

---

## 调优实战案例

### 案例1：频繁 Full GC

```mermaid
graph TD
    A["现象：每隔几分钟一次 Full GC"] 
    A --> B["jstat -gcutil 查看"]
    B --> C["发现老年代使用率在<br/>Full GC 后依然很高（> 80%）"]
    C --> D["jmap dump 堆转储"]
    D --> E["MAT 分析发现<br/>某个 HashMap 持续增长"]
    E --> F["代码审查：静态 Map<br/>只 put 不 remove"]
    F --> G["修复：改用 LRU 缓存<br/>或定期清理"]
    
    style G fill:#a5d6a7
```

### 案例2：Young GC 时间长

```mermaid
graph TD
    A["现象：Young GC 耗时 > 100ms"]
    A --> B["检查新生代大小"]
    B --> C["新生代 4GB → 太大了<br/>每次 GC 扫描范围大"]
    C --> D["调整：-Xmn2g<br/>减小新生代"]
    D --> E["或者改用 G1<br/>自动调节各区域大小"]
    
    style D fill:#a5d6a7
    style E fill:#a5d6a7
```

### 案例3：Metaspace OOM

```mermaid
graph TD
    A["现象：Metaspace OOM"]
    A --> B["原因：大量动态生成类<br/>（CGLIB、反射、Groovy脚本）"]
    B --> C["排查：jstat -gcutil<br/>观察 M（Metaspace）使用率"]
    C --> D["解决方案"]
    D --> D1["增大 MaxMetaspaceSize"]
    D --> D2["检查是否有类加载器泄漏"]
    D --> D3["限制动态类生成"]
    
    style D1 fill:#a5d6a7
```

---

## 调优原则

```mermaid
graph TD
    A["JVM 调优原则"]
    A --> B["1. 先优化代码<br/>再优化 JVM"]
    A --> C["2. Full GC 频率<br/>越低越好"]
    A --> D["3. Xms = Xmx<br/>避免堆动态扩缩"]
    A --> E["4. 新生代不要太小<br/>否则频繁 Minor GC"]
    A --> F["5. 新生代不要太大<br/>否则 Minor GC 耗时长"]
    A --> G["6. 元空间设上限<br/>避免无限增长"]
    A --> H["7. 优先使用 G1<br/>JDK 9+ 默认"]
```

---

## 面试高频问题

### Q1：线上 OOM 怎么排查？

1. 确保开启 `-XX:+HeapDumpOnOutOfMemoryError`
2. 获取堆转储文件
3. 用 MAT 分析大对象和引用链
4. 找到泄漏代码修复

### Q2：线上 CPU 100% 怎么排查？

1. `top` 找到 CPU 高的 Java 进程
2. `top -Hp PID` 找到 CPU 高的线程
3. `printf '%x'` 转十六进制
4. `jstack` 查看该线程堆栈

### Q3：常用的 JVM 参数有哪些？

`-Xms/-Xmx`（堆大小）、`-Xmn`（新生代）、`-Xss`（栈大小）、`-XX:MetaspaceSize`（元空间）、`-XX:+UseG1GC`（收集器）、`-XX:+HeapDumpOnOutOfMemoryError`（OOM dump）。

### Q4：你做过哪些 JVM 调优？

回答模板：
1. **问题现象**：频繁 Full GC / 响应时间长 / OOM
2. **排查过程**：用什么工具（jstat/jmap/MAT）发现了什么
3. **根因分析**：内存泄漏 / 参数不合理 / 大对象
4. **解决方案**：修复代码 / 调整参数 / 更换收集器
5. **优化效果**：Full GC 频率从 X 降到 Y，响应时间从 A 降到 B
