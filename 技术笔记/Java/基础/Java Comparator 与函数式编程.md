---
title: Java Comparator 与函数式编程
tags:
  - Java
  - Comparator
  - Lambda
  - Stream
  - 函数式编程
  - 面试
created: 2026-05-03
description: 系统整理 Comparator 排序规则、Lambda、函数式接口、Stream、Optional 与常见实战场景
---

# Java Comparator 与函数式编程

## 1. Comparator 是什么

`Comparator<T>` 是 Java 用来定义“两个对象如何比较大小”的接口，位于 `java.util` 包中。

它最核心的方法是：

```java
int compare(T o1, T o2);
```

返回值语义：

- 小于 `0`：`o1` 小于 `o2`
- 等于 `0`：`o1` 等于 `o2`
- 大于 `0`：`o1` 大于 `o2`

它的作用是把“排序规则”从“对象本身”里拆出来。

这和 `Comparable<T>` 的区别是：

- `Comparable`：对象“自己知道怎么比较”，是类的自然顺序
- `Comparator`：比较规则由外部定义，适合一个类存在多种排序方式

示例：

```java
public class User {
    private String name;
    private Integer age;
    private Double salary;

    public User(String name, Integer age, Double salary) {
        this.name = name;
        this.age = age;
        this.salary = salary;
    }

    public String getName() {
        return name;
    }

    public Integer getAge() {
        return age;
    }

    public Double getSalary() {
        return salary;
    }

    @Override
    public String toString() {
        return "User{" +
            "name='" + name + '\'' +
            ", age=" + age +
            ", salary=" + salary +
            '}';
    }
}
```

---

## 2. 最基础的 Comparator 写法

最传统的匿名内部类写法：

```java
List<User> users = new ArrayList<>();
users.add(new User("Tom", 22, 8000.0));
users.add(new User("Alice", 19, 12000.0));
users.add(new User("Bob", 25, 9000.0));

Collections.sort(users, new Comparator<User>() {
    @Override
    public int compare(User o1, User o2) {
        return o1.getAge() - o2.getAge();
    }
});
```

这段代码表示：按年龄升序排序。

但这里有一个常见问题：

```java
return o1.getAge() - o2.getAge();
```

这种写法在数值很大时可能溢出，所以更推荐：

```java
return Integer.compare(o1.getAge(), o2.getAge());
```

更安全版本：

```java
Collections.sort(users, new Comparator<User>() {
    @Override
    public int compare(User o1, User o2) {
        return Integer.compare(o1.getAge(), o2.getAge());
    }
});
```

---

## 3. Lambda 写法

`Comparator` 是函数式接口，因为它只有一个抽象方法，所以可以直接用 Lambda。

```java
users.sort((u1, u2) -> Integer.compare(u1.getAge(), u2.getAge()));
```

这和上面的匿名内部类等价，但更短。

再比如按工资排序：

```java
users.sort((u1, u2) -> Double.compare(u1.getSalary(), u2.getSalary()));
```

按名字字典序排序：

```java
users.sort((u1, u2) -> u1.getName().compareTo(u2.getName()));
```

---

## 4. 推荐写法：Comparator 的工厂方法

Java 8 之后，`Comparator` 提供了一套非常好用的静态工厂方法。

### 4.1 comparing

按对象某个字段比较：

```java
users.sort(Comparator.comparing(User::getName));
```

这表示按 `name` 升序排序。

按年龄：

```java
users.sort(Comparator.comparing(User::getAge));
```

按工资：

```java
users.sort(Comparator.comparing(User::getSalary));
```

这是日常开发里最常见的写法。

---

## 5. 基本类型字段排序：comparingInt / comparingLong / comparingDouble

如果比较字段是基本类型，优先用专门方法。

按年龄：

```java
users.sort(Comparator.comparingInt(User::getAge));
```

按工资：

```java
users.sort(Comparator.comparingDouble(User::getSalary));
```

为什么推荐这种写法：

- 避免自动装箱拆箱
- 语义更明确
- 性能通常更好

---

## 6. 逆序排序

### 6.1 整体逆序

```java
users.sort(Comparator.comparingInt(User::getAge).reversed());
```

表示按年龄降序。

### 6.2 先升序再降序的理解

```java
Comparator<User> byAgeDesc = Comparator.comparingInt(User::getAge).reversed();
```

这表示：

1. 先生成“按年龄升序”的比较器
2. 再调用 `reversed()` 反转

---

## 7. 多字段排序

实际业务里，一个字段经常不够。

比如：

- 先按年龄升序
- 年龄相同再按工资降序
- 工资还相同再按名字升序

写法：

```java
users.sort(
    Comparator.comparingInt(User::getAge)
        .thenComparing(Comparator.comparingDouble(User::getSalary).reversed())
        .thenComparing(User::getName)
);
```

这就是典型的链式排序规则。

### 7.1 thenComparing 的含义

`thenComparing` 的意思是：

- 如果第一层比较已经分出大小，就结束
- 如果第一层结果相等，再执行下一层比较

示例：

```java
List<User> users = List.of(
    new User("Tom", 22, 9000.0),
    new User("Alice", 22, 12000.0),
    new User("Bob", 22, 12000.0)
);

List<User> sorted = new ArrayList<>(users);
sorted.sort(
    Comparator.comparingInt(User::getAge)
        .thenComparing(Comparator.comparingDouble(User::getSalary).reversed())
        .thenComparing(User::getName)
);
```

排序结果逻辑：

- 三个人年龄都一样，先看工资
- `12000` 排在 `9000` 前面
- 工资相同的 `Alice` 和 `Bob` 再按名字排

---

## 8. 处理 null

排序时最容易出错的点之一就是 `null`。

比如名字可能为 `null`：

```java
List<User> users = new ArrayList<>();
users.add(new User(null, 22, 8000.0));
users.add(new User("Alice", 19, 12000.0));
users.add(new User("Bob", 25, 9000.0));
```

如果直接写：

```java
users.sort(Comparator.comparing(User::getName));
```

可能抛 `NullPointerException`。

### 8.1 nullsFirst

让 `null` 排前面：

```java
users.sort(Comparator.comparing(
    User::getName,
    Comparator.nullsFirst(String::compareTo)
));
```

### 8.2 nullsLast

让 `null` 排后面：

```java
users.sort(Comparator.comparing(
    User::getName,
    Comparator.nullsLast(String::compareTo)
));
```

### 8.3 多层 null 处理

```java
users.sort(
    Comparator.comparing(
        User::getName,
        Comparator.nullsLast(String::compareTo)
    ).thenComparingInt(User::getAge)
);
```

---

## 9. 常见排序场景

### 9.1 List 排序

```java
users.sort(Comparator.comparingInt(User::getAge));
```

或者：

```java
Collections.sort(users, Comparator.comparingInt(User::getAge));
```

两者区别：

- `List.sort(...)`：更现代，推荐
- `Collections.sort(...)`：旧写法，仍可用

### 9.2 Stream 排序

```java
List<User> sorted = users.stream()
    .sorted(Comparator.comparingInt(User::getAge))
    .toList();
```

注意：

- `List.sort()` 会修改原集合
- `stream().sorted()` 不会修改原集合，而是生成新结果

### 9.3 数组排序

```java
User[] arr = {
    new User("Tom", 22, 8000.0),
    new User("Alice", 19, 12000.0)
};

Arrays.sort(arr, Comparator.comparingInt(User::getAge));
```

### 9.4 TreeSet / TreeMap 中使用 Comparator

```java
Set<User> set = new TreeSet<>(Comparator.comparing(User::getName));
```

这里要特别小心：

`TreeSet` 判断“是否重复”，不是用 `equals()`，而是看比较结果是否为 `0`。

也就是说，如果两个对象：

```java
compare(a, b) == 0
```

那么 `TreeSet` 会认为它们是同一个元素。

例如：

```java
Set<User> set = new TreeSet<>(Comparator.comparingInt(User::getAge));
set.add(new User("Tom", 20, 8000.0));
set.add(new User("Alice", 20, 12000.0));
```

虽然是两个不同的人，但因为年龄相同，比较结果为 `0`，第二个可能加不进去。

所以给 `TreeSet` / `TreeMap` 的比较器，必须理解：

- 比较规则不仅决定顺序
- 还决定“键是否相同”

---

## 10. Comparator 的契约

一个比较器最好满足以下规则。

### 10.1 自反性含义

```java
compare(a, a) == 0
```

自己和自己比较应当相等。

### 10.2 对称性

如果：

```java
compare(a, b) > 0
```

那么应当有：

```java
compare(b, a) < 0
```

### 10.3 传递性

如果：

```java
a > b 且 b > c
```

那么应该有：

```java
a > c
```

如果违反这些规则，排序结果可能不稳定，甚至在某些集合中出现诡异行为。

---

## 11. 不推荐的 Comparator 写法

### 11.1 直接相减

```java
return a - b;
```

问题：

- 可能整数溢出
- 可读性一般

推荐：

```java
return Integer.compare(a, b);
```

### 11.2 compare 中写复杂业务逻辑

错误思路：

```java
users.sort((u1, u2) -> {
    // 做数据库查询
    // 改对象状态
    // 发送日志
    return Integer.compare(u1.getAge(), u2.getAge());
});
```

`compare` 应尽量保持：

- 无副作用
- 纯比较逻辑
- 快速执行

因为排序算法会大量重复调用比较器。

### 11.3 规则不一致

例如：

```java
(a, b) -> 1
```

这种写法不满足比较契约，排序行为会异常。

---

## 12. 实战例子

### 12.1 订单排序

```java
public class Order {
    private String orderNo;
    private Integer priority;
    private Long createTime;

    public Order(String orderNo, Integer priority, Long createTime) {
        this.orderNo = orderNo;
        this.priority = priority;
        this.createTime = createTime;
    }

    public String getOrderNo() {
        return orderNo;
    }

    public Integer getPriority() {
        return priority;
    }

    public Long getCreateTime() {
        return createTime;
    }
}
```

需求：

- 优先级高的排前面
- 优先级相同时，创建时间早的排前面

```java
orders.sort(
    Comparator.comparingInt(Order::getPriority).reversed()
        .thenComparingLong(Order::getCreateTime)
);
```

### 12.2 工单排序

需求：

- 先按状态排序：处理中 > 待处理 > 已解决 > 已关闭
- 再按更新时间倒序

```java
Map<String, Integer> statusRank = Map.of(
    "PROCESSING", 4,
    "PENDING", 3,
    "RESOLVED", 2,
    "CLOSED", 1
);

tickets.sort(
    Comparator.comparingInt(
        ticket -> statusRank.getOrDefault(ticket.getStatus(), 0)
    ).reversed()
    .thenComparing(Ticket::getUpdatedAt, Comparator.reverseOrder())
);
```

这种写法很实用，因为业务状态顺序通常不是自然字典序。

---

## 13. 函数式编程是什么

在 Java 里，“函数式编程”不是说 Java 变成了函数式语言，而是说：

- 可以把“行为”当成参数传递
- 可以用更声明式的方式描述处理流程
- 可以减少样板代码
- 可以更容易组合逻辑

Java 8 之后，函数式编程能力主要来自：

- Lambda 表达式
- 方法引用
- 函数式接口
- Stream API
- Optional
- `java.util.function` 包

核心思想可以概括成一句话：

> 把“做什么”写清楚，而不是把“怎么一步步做”全部展开。

---

## 14. Lambda 表达式

Lambda 本质上是“匿名函数”的简洁表示。

基本语法：

```java
(参数列表) -> 表达式
```

或者：

```java
(参数列表) -> {
    代码块
}
```

示例：

```java
Comparator<User> byAge = (u1, u2) -> Integer.compare(u1.getAge(), u2.getAge());
```

如果只有一个参数，括号可以省略：

```java
Consumer<String> printer = s -> System.out.println(s);
```

如果代码块只有一行返回值，也可以省略 `return`：

```java
Function<String, Integer> lengthFn = s -> s.length();
```

---

## 15. 方法引用

方法引用是 Lambda 的进一步简化。

形式：

- `类名::静态方法`
- `对象名::实例方法`
- `类名::实例方法`
- `类名::new`

示例：

```java
Comparator<User> byName = Comparator.comparing(User::getName);
```

等价于：

```java
Comparator<User> byName = Comparator.comparing(user -> user.getName());
```

更多例子：

```java
Consumer<String> printer = System.out::println;
Supplier<List<String>> listSupplier = ArrayList::new;
Function<String, Integer> parser = Integer::parseInt;
```

---

## 16. 函数式接口

函数式接口：只有一个抽象方法的接口。

典型例子：

- `Runnable`
- `Comparator`
- `Callable`
- `Consumer`
- `Supplier`
- `Function`
- `Predicate`

你也可以自定义：

```java
@FunctionalInterface
public interface PriceCalculator {
    double calc(double originPrice);
}
```

使用：

```java
PriceCalculator vipDiscount = price -> price * 0.8;
System.out.println(vipDiscount.calc(100));
```

`@FunctionalInterface` 不是必须，但强烈建议加上，因为它能让编译器帮你校验接口是否真的只有一个抽象方法。

---

## 17. java.util.function 常用接口

这是函数式编程最常用的一组标准接口。

### 17.1 Function<T, R>

输入一个值，输出一个值。

```java
Function<String, Integer> parse = Integer::parseInt;
Integer x = parse.apply("123");
```

语义：

- `T`：输入类型
- `R`：输出类型

### 17.2 Consumer<T>

输入一个值，做某些事情，但不返回结果。

```java
Consumer<String> printer = System.out::println;
printer.accept("hello");
```

### 17.3 Supplier<T>

不需要输入，返回一个结果。

```java
Supplier<String> uuidSupplier = () -> UUID.randomUUID().toString();
String id = uuidSupplier.get();
```

### 17.4 Predicate<T>

输入一个值，返回布尔值，通常用于条件判断。

```java
Predicate<Integer> adult = age -> age >= 18;
boolean result = adult.test(20);
```

### 17.5 UnaryOperator<T>

输入和输出类型相同的 `Function`。

```java
UnaryOperator<Integer> plusOne = x -> x + 1;
```

### 17.6 BinaryOperator<T>

两个输入，输出一个相同类型结果。

```java
BinaryOperator<Integer> sum = Integer::sum;
int r = sum.apply(3, 5);
```

### 17.7 BiFunction<T, U, R>

两个输入，一个输出。

```java
BiFunction<Integer, Integer, String> concat = (a, b) -> a + ":" + b;
```

---

## 18. 函数组合

函数式编程的一个关键点是“组合”。

### 18.1 Function 的 compose 和 andThen

```java
Function<String, String> trim = String::trim;
Function<String, Integer> length = String::length;

Function<String, Integer> trimThenLength = trim.andThen(length);
```

执行顺序：

1. 先 `trim`
2. 再 `length`

```java
Integer len = trimThenLength.apply("  hello  "); // 5
```

`compose` 则是反过来：

```java
Function<String, Integer> trimThenLength2 = length.compose(String::trim);
```

含义是：

- 先执行 `String::trim`
- 再执行 `length`

### 18.2 Predicate 的组合

```java
Predicate<User> adult = user -> user.getAge() >= 18;
Predicate<User> highSalary = user -> user.getSalary() >= 10000;

Predicate<User> target = adult.and(highSalary);
```

还可以：

```java
adult.or(highSalary);
adult.negate();
```

---

## 19. Stream：函数式编程最常见落地场景

`Stream` 是 Java 函数式编程最常用的场景。

它强调的是“数据流上的操作管道”。

典型处理链：

```java
List<String> result = users.stream()
    .filter(user -> user.getAge() >= 18)
    .sorted(Comparator.comparingDouble(User::getSalary).reversed())
    .map(User::getName)
    .toList();
```

这段代码表示：

1. 从 `users` 生成流
2. 过滤出成年用户
3. 按工资降序
4. 提取名字
5. 收集为列表

这就是典型的声明式写法。

---

## 20. Stream 常用操作

### 20.1 filter

过滤：

```java
users.stream()
    .filter(user -> user.getAge() >= 18);
```

### 20.2 map

转换：

```java
users.stream()
    .map(User::getName);
```

### 20.3 sorted

排序：

```java
users.stream()
    .sorted(Comparator.comparingInt(User::getAge));
```

### 20.4 distinct

去重：

```java
List<Integer> nums = List.of(1, 2, 2, 3, 3, 3);
List<Integer> result = nums.stream().distinct().toList();
```

### 20.5 limit / skip

分页或截断：

```java
users.stream().skip(10).limit(10).toList();
```

### 20.6 collect

收集结果：

```java
List<String> names = users.stream()
    .map(User::getName)
    .toList();
```

或者：

```java
Map<String, Double> map = users.stream()
    .collect(Collectors.toMap(User::getName, User::getSalary));
```

### 20.7 groupingBy

分组：

```java
Map<Integer, List<User>> byAge = users.stream()
    .collect(Collectors.groupingBy(User::getAge));
```

### 20.8 counting

统计：

```java
Map<Integer, Long> ageCount = users.stream()
    .collect(Collectors.groupingBy(User::getAge, Collectors.counting()));
```

---

## 21. Optional：减少空指针判断噪音

`Optional<T>` 用来表示“这个值可能有，也可能没有”。

### 21.1 基本用法

```java
Optional<User> optionalUser = Optional.ofNullable(findUser());
```

### 21.2 读取值

```java
String name = optionalUser
    .map(User::getName)
    .orElse("未知用户");
```

### 21.3 条件执行

```java
optionalUser.ifPresent(user -> System.out.println(user.getName()));
```

### 21.4 链式处理

```java
String result = Optional.ofNullable(user)
    .map(User::getName)
    .map(String::trim)
    .filter(name -> !name.isEmpty())
    .orElse("default");
```

但要注意：

- `Optional` 适合表达返回值“可能为空”
- 不适合把所有字段都改成 `Optional`
- 也不建议在实体类字段上滥用

---

## 22. Comparator 与函数式编程的联系

`Comparator` 本身就是函数式编程在 Java 里的典型代表。

原因：

### 22.1 它是函数式接口

```java
Comparator<User> byAge = (u1, u2) -> Integer.compare(u1.getAge(), u2.getAge());
```

### 22.2 它支持行为组合

```java
Comparator<User> comparator = Comparator.comparingInt(User::getAge)
    .thenComparing(User::getName)
    .reversed();
```

这就是“把小函数拼接成大规则”。

### 22.3 它经常和 Stream 联动

```java
List<User> result = users.stream()
    .filter(user -> user.getAge() >= 18)
    .sorted(Comparator.comparingDouble(User::getSalary).reversed())
    .toList();
```

这是一种非常标准的 Java 函数式处理风格。

---

## 23. 函数式编程的优点

### 23.1 代码更短

对比传统写法：

```java
Collections.sort(users, new Comparator<User>() {
    @Override
    public int compare(User o1, User o2) {
        return Integer.compare(o1.getAge(), o2.getAge());
    }
});
```

函数式写法：

```java
users.sort(Comparator.comparingInt(User::getAge));
```

### 23.2 逻辑更聚焦

你更容易一眼看出“按什么排序”“怎么过滤”“取什么字段”。

### 23.3 更适合组合

多个小规则可以自然拼接：

- `thenComparing`
- `andThen`
- `compose`
- `filter + map + sorted + collect`

### 23.4 更贴近业务表达

比如：

```java
orders.stream()
    .filter(Order::isPaid)
    .sorted(Comparator.comparing(Order::getCreateTime))
    .toList();
```

这比手写循环更接近业务语义。

---

## 24. 函数式编程的限制和误区

### 24.1 不是所有地方都适合

如果逻辑非常复杂，尤其涉及：

- 大量状态变化
- 多层异常处理
- 多步骤分支

纯链式写法可能反而更难读。

### 24.2 不要为了“函数式”而函数式

例如特别长的 Stream 链：

```java
list.stream()
    .filter(...)
    .map(...)
    .flatMap(...)
    .filter(...)
    .sorted(...)
    .collect(...);
```

如果链条过长：

- 不易调试
- 不易断点
- 不易命名中间语义

这时可以拆中间变量。

### 24.3 注意副作用

不推荐在 `map`、`filter`、`compare` 里做副作用操作，比如：

- 改外部变量
- 写日志作为主逻辑
- 发请求
- 改数据库

示例：

```java
list.stream().map(x -> {
    cache.put(x.getId(), x);
    return x.getName();
});
```

这种写法可维护性差。

### 24.4 并行流不要滥用

```java
list.parallelStream()
```

不是写上去就一定更快。

适合并行流的前提通常是：

- 数据量足够大
- 计算足够重
- 任务彼此独立
- 没有共享可变状态

否则可能更慢，甚至有线程安全问题。

---

## 25. 日常开发推荐写法

### 25.1 排序推荐

```java
users.sort(
    Comparator.comparingInt(User::getAge)
        .thenComparing(User::getName)
);
```

### 25.2 过滤 + 转换推荐

```java
List<String> names = users.stream()
    .filter(user -> user.getAge() >= 18)
    .map(User::getName)
    .toList();
```

### 25.3 Null 处理推荐

```java
Comparator<User> byName = Comparator.comparing(
    User::getName,
    Comparator.nullsLast(String::compareTo)
);
```

### 25.4 组合函数推荐

```java
Function<String, String> normalize = String::trim;
Function<String, String> toUpper = String::toUpperCase;

Function<String, String> pipeline = normalize.andThen(toUpper);
```

---

## 26. 面试和实战高频点

### 26.1 Comparator 和 Comparable 区别

- `Comparable`：类内部定义自然顺序
- `Comparator`：类外部定义额外顺序

### 26.2 `Comparator.comparingInt` 为什么优于 `comparing`

- 避免装箱
- 性能更好
- 语义更清晰

### 26.3 `thenComparing` 的作用

- 主排序相等时执行次排序

### 26.4 `nullsFirst` / `nullsLast`

- 解决排序字段可能为空的问题

### 26.5 `TreeSet` 为什么会“丢元素”

- 因为它根据 `compare(...) == 0` 判断重复
- 不只是按 `equals()`

### 26.6 Stream 和集合排序区别

- `list.sort(...)`：原地修改
- `stream().sorted(...)`：生成新流结果

### 26.7 Lambda 为什么能简化代码

- 因为函数式接口只要求一个抽象方法
- 所以可以把“行为实现”直接写成表达式

---

## 27. 一组完整示例

```java
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class Demo {

    public static void main(String[] args) {
        List<User> users = new ArrayList<>();
        users.add(new User("Tom", 22, 8000.0));
        users.add(new User("Alice", 19, 12000.0));
        users.add(new User("Bob", 25, 9000.0));
        users.add(new User("Jerry", 22, 12000.0));

        // 1. Comparator：先按年龄升序，再按工资降序，再按名字升序
        users.sort(
            Comparator.comparingInt(User::getAge)
                .thenComparing(Comparator.comparingDouble(User::getSalary).reversed())
                .thenComparing(User::getName)
        );

        System.out.println("排序后:");
        users.forEach(System.out::println);

        // 2. Predicate：筛选成年人
        Predicate<User> adult = user -> user.getAge() >= 18;

        // 3. Function：提取名字
        Function<User, String> toName = User::getName;

        // 4. Stream：筛选 + 排序 + 映射
        List<String> names = users.stream()
            .filter(adult)
            .sorted(Comparator.comparingDouble(User::getSalary).reversed())
            .map(toName)
            .toList();

        System.out.println("成年人名字:");
        names.forEach(System.out::println);

        // 5. 分组
        Map<Integer, List<User>> byAge = users.stream()
            .collect(Collectors.groupingBy(User::getAge));

        System.out.println("按年龄分组:");
        System.out.println(byAge);
    }
}
```

---

## 28. 总结

### Comparator 的重点

- `Comparator` 用来定义外部排序规则
- 推荐用 `Comparator.comparing...` 系列方法
- 多字段排序用 `thenComparing`
- 降序用 `reversed`
- 空值处理用 `nullsFirst` / `nullsLast`
- 注意 `TreeSet` / `TreeMap` 对比较结果为 `0` 的特殊语义

### 函数式编程的重点

- Lambda 是函数式接口的简洁实现
- 方法引用让代码更短更清晰
- `Function`、`Predicate`、`Consumer`、`Supplier` 是核心标准接口
- `Stream` 是函数式编程最常见应用场景
- 重点不是“写得短”，而是“逻辑可组合、语义清晰、少副作用”

### 一句话记忆

> `Comparator` 解决“怎么排”，函数式编程解决“怎么把行为当数据一样组合起来”。
