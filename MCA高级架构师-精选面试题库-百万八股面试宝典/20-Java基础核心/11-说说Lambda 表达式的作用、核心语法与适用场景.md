Java 中的 Lambda 表达式，是 Java 8 引入的用于创建匿名函数的一种语法，底层机制为“函数式接口”。它让我们可以将行为直接当作参数或变量传递，从而简化代码，支持函数式编程风格。

### 1. 作用与优势

- **简洁性**：替代传统匿名内部类，减少样板代码，提升可读性。S
- **行为传递**：可将操作封闭为 lambda，传给方法或函数式接口，提高代码灵活性。
- **与 Stream 结合**：非常适合用于流式操作中的 filter、map、forEach 等模式。

M

### 2. 核心语法

```java
(parameters) -> expression
// 或带代码块
(a, b) -> { return a + b; }
x -> x * x
() -> System.out.println("Hello")
```

- 参数类型可省略，类型由上下文推断；单参数可省略括号。多语句需使用大括号和 return。

S

### 3. 适用场景

- 任何 **函数式接口**（仅一个抽象方法），如 `Runnable`、`Comparator`、`Consumer` 等
- **集合或数组遍历**：`list.forEach(item -> ...)`
- **事件监听**或**回调**：`button.addActionListener(evt -> ...)`

B

### 4. 与匿名内部类对比

- **性能**：Lambda 使用 `invokedynamic`，无需生成额外类，启动较快且后续执行高效。
- `this` **指向**：Lambda 中 `this` 指向外部类，而匿名类中为自身实例。
- **可读性**更好，结构更清晰。

### 5. 限制与注意点

- 只能用于函数式接口；
- 捕获外部变量必须是“有效 final”；
- 复杂逻辑用 lambda 可能不如声明式方法易读。
