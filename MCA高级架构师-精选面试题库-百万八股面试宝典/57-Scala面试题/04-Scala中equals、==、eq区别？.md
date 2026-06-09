在Scala中，对象比较可以使用equals、==、eq三种方式，它们的行为有所不同：

- equals:在 Scala 中，equals 是从 Java 继承的，可以直接使用，用于比较两个对象的内容是否相等,但使用时需要注意可能出现 NullPointerException。
- ==：在Java中，==对于引用类型来说比较的是地址，对于基本类型来说，进行数值比较。而在Scala中，== 是值相等性的比较，在字符串比较中用于判断两个字符串的内容是否相等，但Scala中== 操作符经过优化会先做 null 检查，从而避免 NullPointerException。
- eq方法:这是 Scala 中对象引用相等性的比较，用于比较两个引用是否指向同一个对象，等同于Java中==使用。

**三者区别表格如下：**

|  |  |  |  |
| --- | --- | --- | --- |
| **方法** | **比较类型** | **适用场景** | **说明** |
| **equals** | 值相等（直接继承自 Java） | 判断内容是否相等（不安全处理 null） | 继承自 Java，需要手动避免 null 引发的异常。 |
| **==** | 值相等（经过优化） | 判断内容是否相等，安全处理 null | 推荐使用，内置 null 检查，避免 NullPointerException |
| **eq** | 引用相等 | 判断两个变量是否指向同一个对象 | 只比较内存地址，不考虑内容是否相等 |

**字符串比较代码示例如下：**

|  |
| --- |
| val str1 = "hello"val str2 = "hello"val str3 = new String("hello")val str4: String = null *// equals: 值相等（小心 null）**println*(str1.equals(str2)) *// true，内容相等**println*(str1.equals(str3)) *// true，内容相等* *// println(str4.equals(str1)) // 抛出 NullPointerException* *// ==: 值相等（推荐）**println*(str1 == str2) *// true，内容相等**println*(str1 == str3) *// true，内容相等**println*(str4 == str1) *// false，安全处理 null* *// eq: 引用相等**println*(str1.eq(str2)) *// true，str1 和 str2 都指向字符串池中的同一对象**println*(str1.eq(str3)) *// false，str3 是通过 new 创建的，不同的引用* |

## ​
