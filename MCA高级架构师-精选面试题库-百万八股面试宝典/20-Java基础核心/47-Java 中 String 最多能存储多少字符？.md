# 编译期

Java 源代码中的字符串字面量必须编译进 `.class` 文件常量池，它们以 UTF‑8 编码方式存储。根据 JVM 规范，常量池中的单个 `CONSTANT_Utf8` 项目长度由无符号 16 位整数（u2）表示，最多可存储 **65535** 字节内容。一旦一个字符串字面量的 UTF‑8 编码长度超出此限制，编译器将报错：“UTF8 representation for string is too long for the constant pool”。由于中文通常占用 3 个字节，这导致单个中文字面量约能包含 **21845** 个字符。

# 运行时

运行时，`String.length()` 返回值类型为 `int`，理论最大值为 **2 147 483 647** (`Integer.MAX_VALUE`)。Java 内部用 `char[]`（每个字符最多占 2 字节）或在 Java 9+ 使用 LATIN1 压缩数组。因此理论上可存储接近 **21 亿** 个字符，占用约 **4 GB 堆空间**（2 字节 × 亿级字符），前提是系统具备足够内存。

​
