在 Java 中删除 `HashMap` 中的条目时要避免 `ConcurrentModificationException`。以下几种方式可供参考：

### 1. 使用 `Iterator` 的 `remove()` 方法

```java
Iterator<Map.Entry<String, String>> iter = map.entrySet().iterator();
while (iter.hasNext()) {
    Map.Entry<String,String> e = iter.next();
    if ("王五".equals(e.getValue())) {
        iter.remove();
    }
}
```

**优点**：遍历时删除安全，不会抛并发修改异常；  
**缺点**：代码较繁琐；在多线程环境下仍需外部线程同步或使用并发容器。 M

### 2. 使用 `entrySet().removeIf(...)`（推荐）

```java
map.entrySet().removeIf(e -> "王五".equals(e.getValue()));
```

**优点**：一行 lambda，简洁、安全；内部使用 `Iterator.remove()` 机制，性能高，代码优雅。  
**缺点**：修改的是原 map，不适合并发频繁读写时单纯使用。S

### 3. 使用 Java 8 Stream 生成一个新 Map

```java
Map<String,String> filtered = map.entrySet().stream()
.filter(e -> !"王五".equals(e.getValue()))
.collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
```

**优点**：避免原 map 修改，函数式风格；  
**缺点**：生成新 map，需额外内存，原引用不变，可能需重新赋值；不适用于非常大数据集。

### 4. 使用 `ConcurrentHashMap` + `forEach/remove()`

```java
ConcurrentHashMap<String,String> cmap = new ConcurrentHashMap<>(map);
cmap.forEach((k,v) -> {
    if ("王五".equals(v)) cmap.remove(k);
});
```

**优点**：适用于多线程并发场景；  
**缺点**：代码稍复杂，且迭代和删除可能造成最终一致性延迟。

### 5. 复制键集合再删除（适用于不可修改原 map 场景）

```java
for (String key : new ArrayList<>(map.keySet())) {
    if ("王五".equals(map.get(key))) map.remove(key);
}
```

**优点**：简单，避免遍历时修改同一结构；  
**缺点**：额外复制开销，在大 map 时效率低。 B
