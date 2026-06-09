Java 的异常处理依托于 `try‑catch‑finally` 结构，保证程序在出现异常时仍能稳定执行。主要机制如下：

​**1. try 块：**  
包裹可能抛出异常的核心逻辑。若发生异常，跳转到匹配的 catch 块。

**2. catch 块：**  
可配置多个 catch，按先后顺序捕获异常类型。首个匹配的 catch 会执行处理逻辑，例如记录日志或恢复流程。若未捕获，异常会传递给上层调用方 M。

**3. finally 块：**  
无论是否抛出异常，finally 都确保会被执行，常用于资源清理，如关闭文件或数据库连接 S。但若出现 `System.exit()`、JVM 崩溃等特殊情况，finally 可能不会执行。

**4. 异常传播（propagation）：**  
若当前方法未捕获异常，会将异常逐层交给调用方处理，直到 `main`，最终未处理会由 JVM 报错终止程序 B。

**5. try‑with‑resources（Java 7+）：**  
是一种简化资源管理的语法，在 `try(...)` 中声明资源，它会自动调用 `close()`，无需 explicit `finally`。在某些情况下替代 finally 更安全。
