- 常用结构有任务 channel、固定数 worker goroutine、WaitGroup 等。
- 代码：

```go
func WorkerPool(n int, tasks <-chan Task) {
    var wg sync.WaitGroup
    for i := 0; i < n; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for t := range tasks {
                t.Run()
            }
        }()
    }
    wg.Wait()
}
```

适用于批量任务处理、爬虫、并发计算等。
