Java 提供两种排序接口：`Comparable` 用于定义类的**自然排序**，`Comparator` 则支持**自定义和多种排序方式**，它们在使用场景和实现方式上有明显区别。M

​

`Comparable` 接口由需要排序的类实现，通过 `compareTo()` 方法指定对象的默认比较规则。这种方式适合类内部其本身“天然”的排序，比如 `String`、`Integer`、或者实体类按照 ID 排序 。实现简单易用，`Collections.sort(list)` 即可自动识别。S

​

`Comparator` 是外部比较器，通过实现 `compare(T o1, T o2)` 方法，可以在类外定义多个比较策略。适用于无法修改源代码的类或需要根据不同字段进行排序的场景，例如先按姓名排序，再按年龄排序。这种方式灵活但需要额外定义逻辑。

---

### 对比总结

- **定义位置**：Comparable 实现在类内部；Comparator 是独立的外部比较器。
- **排序方式**：Comparable 提供单一、固定的自然排序；Comparator 可实现多种排序逻辑。B
- **使用场景**：若类有明确的默认排序，使用 Comparable；如要多样排序或操作第三方类，用 Comparator。
