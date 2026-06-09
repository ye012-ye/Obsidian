k.eq(curKey) 和 k.equals(curKey) 都用于比较两个对象是否相等，但它们之间有一些区别。

- k.eq(curKey): Scala 中用于检查两个对象是否是同一个引用的方法，如果 k 和 curKey 是同一个对象（即它们在内存中的地址相同），则返回 true；否则返回 false，这个方法在底层会直接调用 Java 中的 == 操作符，因此相当于 Java 中的对象引用比较。
- k.equals(curKey)： Scala 中用于检查两个对象是否在逻辑上相等的方法，默认情况下，这个方法与 Java 中的 equals 方法具有相同的行为，即如果两个对象的内容相同，则返回 true，否则返回 false。可以通过重写类的 equals 方法来定义自定义的相等性比较逻辑。

代码测试如下：

|  |
| --- |
| **val** str1 = **"Hello"**  **val** str2 = **new** String(**"Hello"**)  **val** str3 = **"Hello"**    *println*(str1 eq str2) *// false，因为 str1 和 str2 是不同的对象实例*  *println*(str1.equals(str2)) *// true，因为它们的内容相同*    *println*(str1 eq str3) *// true，因为 str1 和 str3 指向相同的对象实例*  *println*(str1.equals(str3)) *// true，因为它们的内容相同* |
