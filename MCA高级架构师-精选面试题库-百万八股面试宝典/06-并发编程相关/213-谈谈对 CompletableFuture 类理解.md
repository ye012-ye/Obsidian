`CompletableFuture<T>` 是 Java 中一个功能强大的异步编程类，它同时实现了 `Future<T>` 与 `CompletionStage<T>` 接口，具备普通 Future 的阻塞等待能力，同时支持复杂的任务编排和链式操作。M

### 一、创建方式与区别

- 使用 `supplyAsync(Supplier<U>)` 创建带返回结果的异步任务。此任务通过 `Supplier<U>` 提供执行逻辑，异步完成后返回一个带结果的 `CompletableFuture<U>`。
- 使用 `runAsync(Runnable)` 创建无返回结果任务，适用于只执行操作、不需要结果的情形，返回类型为 `CompletableFuture<Void>`。

两者都可指定 `Executor`，否则默认使用 `ForkJoinPool.commonPool()`。

### 二、任务编排与链式调用

- `thenApply(Function<T, U>)`：接收前一个阶段的结果，同步执行函数逻辑，将结果转换为新值并返回新的 `CompletableFuture<U>`，类似 stream 的 `map` 操作。
- `thenCompose(Function<T, CompletableFuture<U>>)`：用于串接返回另一 `CompletableFuture<U>` 的异步任务，自动扁平化结果为 `CompletableFuture<U>`，类似 `flatMap`。

除此之外，可使用 `thenRun()`、`thenAccept()` 等方法串联没有返回值的处理逻辑。S

### 三、组合多个异步任务

- `thenCombine(...)`：将两个并行执行的 CompletableFuture 的结果组合为一个新值，例如将两个异步结果加在一起。
- `allOf(...)` / `anyOf(...)`：等待多个 Future 完成后统一继续执行。`allOf()` 等待全部完成，`anyOf()` 任一完成立即返回。`allOf()` 返回 `CompletableFuture<Void>`，需单独获取各子 Future 的结果。

### 四、异常处理与结果获取

- `get()` 方法阻塞主线程等待结果或异常，抛出 `ExecutionException` 或 `InterruptedException`。
- `join()` 則类似 `get()`，但抛出 `CompletionException` 而非checked异常，适合在流式 API 中使用。
- 对异常处理可使用 `.handle(...)`、`exceptionally(...)` 等方法，在链中提供回退逻辑或容错机制。B
