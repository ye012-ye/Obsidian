Java 中的运行时异常（RuntimeException 及其子类）通常反映程序逻辑错误，不用显式捕获，常见异常如下：M

#### 1. **NullPointerException**

- 出现场景：对 `null` 对象调用方法或访问字段。
- 应对策略：变量初始化、增加非 null 检查或使用 `Optional`避免 NPE。

#### 2. **ArrayIndexOutOfBoundsException / StringIndexOutOfBoundsException**

- 场景：访问数组或字符串时使用非法下标（< 0 或 ≥ 长度）。
- 应对：保证索引合法或使用安全的集合访问方法 。

#### 3. **ClassCastException**

- 场景：将对象强制转换为非其实际类型。
- 对策：使用 `instanceof` 判断类型后再转换。

#### 4. **IllegalArgumentException**

- 场景：方法调用时传入不合法参数。
- 应对：入参校验，检查范围或格式后抛出有意义的异常。

#### 5. **IllegalStateException**

- 场景：对象状态不符合方法调用时抛出（如迭代删除错误、状态不一致）。
- 应对：检查前置条件或状态转换逻辑。S

#### 6. **ArithmeticException**

- 场景：如除以零等非法算术操作。
- 对策：输入校验，判断除数是否为 0 。

#### 7. **NumberFormatException**

- 场景：将非数字字符串转换为数字类型失败。
- 应对：增加格式校验或捕获异常后处理 。

#### 8. **UnsupportedOperationException**

- 场景：执行不支持的操作（如不可修改集合的 `add()`）。
- 对策：事先确认是否可用，或改用支持该操作的实现。B

#### 9. **ConcurrentModificationException**

- 场景：在迭代期间修改集合结构（非通过迭代器的 `remove()`）。
- 应对：使用并发安全结构（如 `CopyOnWriteArrayList`）或正确使用迭代器。
