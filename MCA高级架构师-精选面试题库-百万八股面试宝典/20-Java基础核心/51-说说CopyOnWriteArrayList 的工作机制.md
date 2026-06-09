`CopyOnWriteArrayList` 是 Java 并发包中为 **读多写少** 场景专门设计的线程安全 `List` 实现，它通过“写时复制”机制保证安全与简洁。 M

### 原理

- **写操作**（如 `add`, `remove`, `set`）：先对底层数组进行一次完整复制，然后在副本上修改，最后通过 `volatile` 引用切换到新数组，并释放锁。
- **读操作**（如 `get`, `iterator`）：直接读取当前数组，无需锁，迭代器基于创建时的数组快照，因此安全无 `ConcurrentModificationException`。

### 使用场景与示例

适用于：

- **迭代远多于修改** 的场景，例如配置列表、观察者集合等。

```java
CopyOnWriteArrayList<String> configs = new CopyOnWriteArrayList<>();
configs.add("A");
configs.add("B");

Iterator<String> it = configs.iterator();
configs.add("C"); // 不影响 it，仍旧只遍历 A 和 B
while (it.hasNext()) {
    System.out.println(it.next());
}
```

### 优点

1. **无锁读取，性能优**：多线程读取互不干扰，效率高。S
2. **迭代安全，强一致性快照**：迭代期数据固定，不抛 `ConcurrentModificationException`。

### 不足

1. **写入开销大**：每次修改都要复制数组，影响性能和内存。
2. **非实时一致性**：迭代期间无法看到后续修改，属于弱一致性模型。B
3. **迭代器不支持修改操作**：如 `iterator.remove()` 会抛 `UnsupportedOperationException`。
