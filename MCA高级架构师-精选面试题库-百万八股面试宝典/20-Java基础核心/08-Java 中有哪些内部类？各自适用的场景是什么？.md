Java 中定义在另一个类内部的类统称为**嵌套类**，具体可分为以下四种类型，适用场景如下：

#### 1. 非静态成员内部类（Inner Class）

定义在类内部且没有 `static` 修饰，其对象与外部类实例关联，能访问外部类的所有成员（包括 private）。  
**何时使用**：在实现复杂逻辑时，需共享外部类状态或封装辅助行为。M

```java
public class Outer {
    private int x = 5;
    class Inner {
        void show() { System.out.println(x); }
    }
}
```

**特点**：

- 依赖外部实例，不支持定义静态成员；
- 可用 `Outer.Inner inner = outer.new Inner();` 创建。

#### 2. 静态嵌套类（Static Nested Class）

使用 `static class` 声明，与外部类实例无依赖，仅能访问外部类静态成员。  
**何时使用**：封装与外部状态无关、但作为逻辑归属的帮助类。

```java
public class Outer {
    static class Nest {
        void greet() { System.out.println("Hi"); }
    }
}
```

**特点**：

- 可直接通过 `Outer.Nest n = new Outer.Nest();` 实例化；
- 不持有外部类引用，减少内存耦合。S

#### 3. 方法局部内部类（Local Inner Class）

定义在方法内部，作用域局限于方法块，能访问该方法里的 final 或 有效 final 变量（Java 8 起）。  
**何时使用**：当只在某方法里使用辅助逻辑时，提升组织结构清晰度。

```java
void process(String msg) {
    class Local {
        void print() { System.out.println(msg); }
    }
    new Local().print();
}
```

**特点**：

- 作用域小，有助封装；
- 从 Java 8 后无需显式 final。B

#### 4. 匿名内部类（Anonymous Inner Class）

没有类名，定义时即实例化，常用于实现接口或子类的立即调用。  
**何时使用**：一次性简短逻辑，例如事件处理、回调或策略实现。

```java
button.addActionListener(new ActionListener() {
    @Override
    public void actionPerformed(ActionEvent e) {
        // handle click
    }
});
```
