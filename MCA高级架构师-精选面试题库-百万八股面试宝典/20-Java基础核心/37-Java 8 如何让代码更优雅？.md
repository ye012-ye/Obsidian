Java 8 提炼出函数式编程思想，让代码更简洁、可读、易维护。核心包括三大块：M

### 1. **Lambda 表达式**

- 用 `(params) -> expression` 替换繁琐的匿名类，例如：

```java
list.forEach(item -> System.out.println(item));
```

- 最佳实践：优先使用标准函数式接口（如 `Function`, `Consumer`），添加 `@FunctionalInterface`，避免在 Lambda 中写复杂逻辑；保持一行、变量名表达意图 。S

### 2. **方法引用**

- 如果 Lambda 只是调用已有方法，就用方法引用更清晰安全，例如：

```java
list.stream().map(String::toLowerCase).forEach(System.out::println);
```

- 四种形式：静态、实例、特定对象、构造器引用，既可读又少出错。

### ​3. **Stream API**

- 构建处理流水线，通过 `.stream()` + 中间操作（filter/map/sorted） + 终端操作（collect/reduce/count）处理集合，逻辑一脉相承 。B
- 支持懒执行、并行处理、链式调用，让意图更直观。
- 示例：

```java
long count = list.stream()
.filter(s -> s.startsWith("A"))
.map(String::toUpperCase)
.sorted()
.count();
```

- 避免常见误区：流不会改变原始集合，方法引用有助读代码。
