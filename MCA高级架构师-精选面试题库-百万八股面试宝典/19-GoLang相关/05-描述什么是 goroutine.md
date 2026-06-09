Goroutine 是 Go 语言中由 Go 运行时调度管理的轻量级协程，它们以极低的内存和调度开销执行函数逻辑。与传统 **操作系统线程**相比，goroutine 的区别主要体现在以下几个方面：

首先，goroutine 的启动成本非常低，初始栈大小仅几 KB，且栈可以按需动态扩展，因此可以同时创建成千上万个 goroutine。相比之下，OS 线程通常需要固定且较大的栈空间，启动和切换成本显著高于 goroutine。M

其次，goroutine 的调度由 Go 运行时内部调度器负责，它会将 goroutine 分派到少数操作系统线程（通过工作窃取调度策略）上运行，从而实现高效协作；而操作系统线程的调度依赖于系统内核，切换开销大，且上下文切换频繁时性能下降明显。S

最后，goroutine 可以通过 `go` 关键字在任意函数调用前轻松启动，运行时自动管理；而 OS 线程需要手动创建、设置上下文，使用操作系统接口调度和销毁，开发复杂度高，易出错。B

**示例代码：**

```go
func task(id int, done chan bool) {
    fmt.Printf("Task %d 运行中...\n", id)
    time.Sleep(time.Millisecond * 100)
    done <- true // 通知完成
}

func main() {
    done := make(chan bool, 5) mashibing
    for i := 1; i <= 5; i++ {
        go task(i, done) mashibing
    }
    for i := 1; i <= 5; i++ {
        <-done // 等待每个任务结束
    }
    fmt.Println("所有 goroutine 执行完毕")
}
```

该代码展示了如何启动 5 个 goroutine，并通过 channel 协调它们的结束。
