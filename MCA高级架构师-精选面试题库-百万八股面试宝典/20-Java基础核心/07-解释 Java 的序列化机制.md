Java 序列化（Serialization）是将一个 Java 对象的状态转换成字节流，从而支持持久化存储或网络传输；反序列化将该字节流恢复成原始对象。

M

#### 1. 如何启用序列化

- 类需实现 `java.io.Serializable`（标记接口），使其可被 `ObjectOutputStream` 写出，`ObjectInputStream` 读入。
- 非静态、非瞬态（`transient`）字段默认参与序列化。
- `transient` 修饰的字段不会被序列化，反序列化后为默认值（如 `int` = 0, `String` = null）。

#### 2. 控制版本兼容性

- `static final long serialVersionUID` 用以版本匹配，手工声明可避免自动生成导致的兼容性问题；若版本不一致出现 `InvalidClassException`。

S

#### 3. 自定义序列化行为

- 实现 `writeObject(ObjectOutputStream)` 与 `readObject(ObjectInputStream)`：在调用 `defaultWriteObject()` 后，可插入数据检查或额外逻辑。
- `readResolve()`：在反序列化最后替换或校正返回对象（如保证单例），比直接使用 `readObject()` 更清晰。

B

#### 4. 安全与性能优化

- **安全**：禁止类被反序列化，重写 `readObject()` 抛异常；或用 `readResolve()` 控制实例；推荐采用序列化代理模式（序列化期间替换为简单 DTO，对其反序列化时再恢复原始对象） 。
- **性能**：使用 `Externalizable` 自定义读写逻辑，减少无用字段；或切换到更高效的序列化库，如 Protobuf、Kryo 。
