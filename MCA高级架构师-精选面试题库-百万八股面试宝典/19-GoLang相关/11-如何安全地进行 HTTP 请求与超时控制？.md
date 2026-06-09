**答案：**

```go

ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
resp, err := http.DefaultClient.Do(req)
if err != nil {
    // 可能是超时或其它错误
}
defer resp.Body.Close()
```

确保任何情况下都会 `cancel()` 和 `defer Close()`，避免 goroutine 泄漏和连接泄漏。
