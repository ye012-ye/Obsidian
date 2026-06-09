在 Java 中，对象的克隆机制主要通过 `Cloneable` 接口和 `Object.clone()` 方法实现，分为浅拷贝和深拷贝两种方式。

### 1. 浅拷贝（Shallow Copy）

- `Object.clone()` 默认会复制对象本身，但**字段引用仍然指向原对象**，会导致可变字段共享。
- 使用时需：

1. 实现 `Cloneable` 接口；
2. 重写 `clone()` 方法，调用 `super.clone()`；
3. 将方法设为 `public` 并进行类型转换。M

```java
class Person implements Cloneable {
    String name;
    Address address; // Address 是可变对象

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone(); // 默认浅拷贝
    }
}
```

- 若克隆后修改字段内容，会影响两者状态。

S

### ​2. 深拷贝（Deep Copy）

- 要让克隆对象与原对象互不影响，**需要复制引用类型的字段**。
- 方法：

1. 确保被引用类也支持克隆（实现 `Cloneable` 并重写 `clone()`）；
2. 在 `clone()` 中先调用 `super.clone()` 创建对象，然后对可变字段执行克隆。B

```java

class Address implements Cloneable {
    String city;
    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}

class Person implements Cloneable {
    String name;
    Address address;

    @Override
    public Object clone() throws CloneNotSupportedException {
        Person copy = (Person) super.clone();
        copy.address = (Address) address.clone(); // 深克隆 address
        return copy;
    }
}
```

这样，两个对象间就不会共享 `address`，修改互不干扰。
