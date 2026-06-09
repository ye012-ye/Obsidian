Java 中常见的对象创建方式包括：M

**1. 使用** `new`  
最常见的方法，通过调用构造器分配内存并初始化对象，如 `new Foo()`，构造函数会被调用。

**2. 反射机制（**`Class.newInstance()` **/** `Constructor.newInstance()`**）**

- `Class<?> cls = Foo.class; Foo obj = cls.newInstance();` — 调用无参构造器。
- 也可通过 `Constructor<Foo> ctor = Foo.class.getConstructor(...); ctor.newInstance(args)` 调用带参构造器。  
  此方式适合动态加载类，但是要求相关构造器可访问。

S

**3.** `clone()` **方法**  
当类实现 `Cloneable` 后，可使用 `super.clone()` 创建对象副本，无需再调用构造器。但默认是浅拷贝，需要手动调整实现深拷贝。

**4. 反序列化**  
通过 `ObjectInputStream` 从序列化流中读取对象，如 `ois.readObject()`，创建新实例时不调用目标类构造器。

**5.** `Constructor.newInstance()`**（反射的另一种形式）**  
显式通过 `Constructor` 调用构造器，即使是私有构造器亦可（需 `setAccessible(true)`)。B
