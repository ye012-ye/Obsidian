1. **同步性与线程安全**

- `Hashtable` 是 **线程安全** 的，所有方法都被 `synchronized` 同步，任何时刻只允许一个线程访问，因此在多线程写操作时不会出现数据结构损坏，但性能较差。
- `HashMap` 默认 **不线程安全**，多线程环境下若无外部同步机制，可能导致数据混乱、程序异常等问题 。

2. **键和值是否允许为** `null`

- `Hashtable`**不允许**键或值为 `null`，若插入会抛出 `NullPointerException`。
- `HashMap` 允许一个 `null` 键和多个 `null` 值，这为程序设计提供了更灵活的选择。

3. **迭代器机制**

- `Hashtable` 使用的是 `Enumerator`，**不属于 fail-fast** 机制，线程修改过程可能不会立即抛异常。
- `HashMap` 的迭代器是 **fail-fast** 的，若在迭代过程中结构被修改（非通过自身 `remove()` 方法），会抛出 `ConcurrentModificationException`。

4. **类层次结构与历史地位**

- `Hashtable` 是 Java 1.0 时代的老类，继承自已废弃的 `Dictionary` 类，属于 **遗留类** 。
- `HashMap` 是 Java 1.2 引入的集合框架成员，继承自 `AbstractMap` 并实现 `Map` 接口，是更现代和常用的实现。

5. **性能和使用推荐**

- 由于无同步机制，`HashMap` 在单线程及读多写少的场景中，性能显著优于 `Hashtable`。
- 如果需要线程安全的 Map，推荐使用 `ConcurrentHashMap` 或使用 `Collections.synchronizedMap()` 包装 `HashMap`，而非直接使用效率低下的 `Hashtable`。

### 总结

|  |  |  |
| --- | --- | --- |
| **比较项** | `HashMap` | `Hashtable` |
| 同步性 | ​不安全，多线程需外部同步 | ​线程安全，方法内部同步 |
| 是否允许 `null` | ​允许一个 `null`  键及多个值 | 不允许键或值为 `null` |
| 迭代机制 | fail-fast `Iterator` | 非 fail-fast `Enumerator` |
| 类地位 | 集合框架现代实现 | 遗留类（Java 1.0） |
| 推荐使用 | ​单线程/高性能需求 | ​现代建议用 `ConcurrentHashMap` |
