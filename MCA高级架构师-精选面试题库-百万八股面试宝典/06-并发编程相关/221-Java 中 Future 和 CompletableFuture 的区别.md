在 Java 异步编程中，`Future` 与 `CompletableFuture` 都代表尚未完成的任务结果，但其设计目标、特性和使用方式存在明显差异：

### 一、Future（Java 5）

- `Future<V>` 是表示异步计算结果的接口，执行任务后可通过 `get()` 方法阻塞等待结果，或使用 `cancel()` 尝试取消任务。
- 缺乏回调能力，**无法非阻塞处理完成事件**。若需多个异步操作组合，必须手动控制等待与同步逻辑。
- 异常只能通过 `get()` 捕获包装后的 `ExecutionException`，缺少便捷的异常处理机制。

### 二、CompletableFuture（Java 8 引入）

- 实现了 `Future` 和 `CompletionStage` 接口，既能像 `Future` 一样阻塞等待，也能通过 `complete()` 手动完成任务。可通过 `supplyAsync()` 或 `runAsync()` 直接启动异步操作。
- **非阻塞式链式回调**：支持 `thenApply()`、`thenAccept()`、`thenRun()`等方法，可以在异步任务完成后继续处理，而无需阻塞主线程。
- **任务组合灵活**：提供 `thenCompose()`、`thenCombine()`、`allOf()`、`anyOf()` 等方法，便于串行或并行组合多个异步任务。
- **完善的异常处理**：提供 `exceptionally()`、`handle()` 等方法，可在任务链中优雅处理异常并返回备用结果或触发补偿逻辑。

### 三、对比

|  |  |  |
| --- | --- | --- |
| **特性** | **Future** | **CompletableFuture** |
| 阻塞 vs 非阻塞 | 通过 `get()` 阻塞；无回调机制 | 支持链式回调，无需阻塞调用线程 |
| 任务组合与串联 | 不支持组合或流式操作 | 支持 `thenCompose`、`thenCombine`、`allOf` 等组合操作 |
| 异常处理 | 仅能在 `get()` 时捕获 | 提供链式异常处理方法，如 `exceptionally()`、`handle()` |
| 完成控制 | 无法手动完成，仅由 Executor 调度 | 可手动调用 `complete()` 或 `completeExceptionally()` 完成任务 |
| 引入时间 | Java 5 | Java 8，引入函数式编程风格 |

---

### 四、使用示例

**Future 示例**（阻塞获取结果）：

```java
Future<Integer> f = executor.submit(() -> {
    Thread.sleep(1000);
    return 42;
});
Integer result = f.get(); // 必须阻塞等待
```

**CompletableFuture 示例**（链式处理、非阻塞）：

```java
CompletableFuture<Integer> future =
CompletableFuture.supplyAsync(() -> 42);
future.thenApply(n -> n * 2)
.thenAccept(System.out::println);
```

**多任务组合**：

```java
CompletableFuture<Integer> f1 = CompletableFuture.supplyAsync(() -> 10);
CompletableFuture<Integer> f2 = CompletableFuture.supplyAsync(() -> 20);
f1.thenCombine(f2, Integer::sum)
.thenAccept(sum -> System.out.println("Sum: " + sum));
```

**异常处理**：

```java
CompletableFuture.supplyAsync(() -> 10 / 0)
.exceptionally(ex -> 0)
.thenAccept(System.out::println);
```

### 总结：

- `Future` 提供最基础的异步执行机制，但只能阻塞等待结果，缺乏组合能力与异常处理支持。
- `CompletableFuture` 拥抱函数式编程风格，支持 **非阻塞、链式组合、异常处理** 和 **手动完成控制**，更适用于现代复杂异步流程。对于构建响应式、可组合性强的异步系统，`CompletableFuture` 是更优的选择。
