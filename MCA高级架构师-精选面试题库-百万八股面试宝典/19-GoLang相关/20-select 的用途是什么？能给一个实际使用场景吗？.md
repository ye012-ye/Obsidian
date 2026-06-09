- `select` 用于监听多个 channel 操作。
- 可处理超时：

```go
select {
    case data := <-ch:
    // 正常处理
    case <-time.After(time.Second * 5):
    // 超时逻辑
}
```

- 适用于 multiplexing、超时取消、并发控制等场景。
