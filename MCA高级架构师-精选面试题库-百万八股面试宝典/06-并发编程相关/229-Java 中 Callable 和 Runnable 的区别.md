在 Java 并发编程中，`Callable` 和 `Runnable` 都用于定义可由其他线程执行的任务，但二者在几个方面存在关键差异：M

首先，**返回值**方面，`Runnable` 的 `run()` 方法返回 `void`，无返回值；而 `Callable<V>` 的 `call()` 方法可以返回类型为 `V` 的结果，执行任务后可以通过 `Future<V>` 获取计算结果。

其次，**异常处理**上，`Runnable` 的 `run()` 方法不能声明抛出受检异常，必须在方法内部处理；而 `Callable.call()` 可以声明抛出受检异常，调用者可通过 `Future.get()` 捕获和处理 `ExecutionException`。

再者，**类型支持**上，`Callable` 是一个泛型接口，可指定返回类型；`Runnable` 不支持泛型，仅适合不需要结果的任务。S

最后，在**执行方式**上，`Runnable` 的实例既可以传给 `Thread` 的构造函数，也可提交给 `ExecutorService.execute()` 或 `submit()`；而 `Callable` 必须通过 `ExecutorService.submit()` 提交，不能直接用于创建 `Thread` 对象。B

**总结：**如果任务无需返回值，也没有受检异常需求，可以选择 `Runnable`，适用于“fire-and-forget”类型的轻量任务；若任务需要返回结果或潜在受检异常传播，应使用 `Callable` 接口，并通过 `Future` 获取执行结果与异常状态。
