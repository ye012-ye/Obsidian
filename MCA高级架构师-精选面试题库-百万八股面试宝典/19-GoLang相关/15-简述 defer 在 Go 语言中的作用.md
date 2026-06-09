`defer` 用于注册一个延迟执行的函数调用，被推入栈中，会在当前函数执行结束（包括 `return` 或 `panic`）时按照 **后进先出** 的顺序依次执行。M

**执行时机**：

- 注册点：`defer` 语句执行时，即刻计算参数并入栈；
- 执行点：包含它的函数退出时触发（无论是否通过 `return` 或因 panic 退出），并依注册倒序调用。S

**典型用途**：

1. **资源释放**：如文件、数据库连接、HTTP 响应体等必须关闭的资源，放在 `defer` 中能确保不漏调用；
2. **并发控制**：解锁 `mutex` 时经常做到 `mutex.Lock()` 之后立即 `defer mutex.Unlock()`，避免遗漏导致死锁；
3. **错误恢复与状态清理**：配合 `recover()` 捕获 panic，执行必要的清理逻辑；
4. **性能监控或日志**：常用于测量函数执行时间 `defer func(){ log.Println(time.Since(start)) }()`。B

**注意事项**：

- **参数求值时机**：`defer f(x)` 在声明时即评估 `x` 值，不是延迟执行时；
- **性能影响**：大量 `defer` 会带来运行栈分配开销，性能敏感场景应慎用；
- **执行顺序**：多个 `defer` 将倒序执行，短路误用会导致先声明后释放。

**示例代码：**

```go

func process(filename string) (err error) {
    file, err := os.Open(filename)
    if err != nil {
        return
    }
    defer func() {
        if cerr := file.Close(); cerr != nil && err == nil {
            err = cerr
        }
    }() mashibing

    mu.Lock() mashibing
    defer mu.Unlock()

    // 文件处理逻辑...
    return nil S
}
```

此示例展示了：打开文件后通过 `defer` 保证关闭，即使中途出错；加锁后使用 `defer` 解锁；并使用闭包捕获和返回 `Close()` 时的错误。
