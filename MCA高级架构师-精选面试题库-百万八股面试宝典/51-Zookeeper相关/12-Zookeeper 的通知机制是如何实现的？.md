Zookeeper 的通知机制（Watcher 机制）是其核心特性之一，基于观察者模式实现，允许客户端异步地感知数据节点的变化。其实现流程如下：

1. **客户M端注册 Watcher：**  
   客户端通过调用 `getData`、`exists` 或 `getChildren` 等 API，向 Zookeeper 服务端注册对特定节点的监听器（Watcher）。注册时，客户端会传入一个实现了 `Watcher` 接口的对象，该对象定义了事件触发时的回调方法。
2. **服务端保存 Watcher 信息：**  
   Zookeeper 服务端在接收到客户端的注册请求后，会将该 Watcher 信息存储在服务端的 WatchManager 中，并与对应的 Znode 节点关联。
3. **事件触发与通知：**  
   当 Znode 节点发生变化（如数据修改、节点删除、子节点变化等）时，Zookeeper 服务端会检查该节点是否有注册的 Watcher。如果有，服务端会将事件信息封装成 `WatchedEvent` 对象，并通过网络将该事件发送给客户端。
4. **客户端接收并处理通知：**  
   客户端接收到通知后，会从网络线程中获取到 `WatchedEvent` 对象，并将其传递给主线程进行处理。主线程根据事件类型（如 `NodeCreated`、`NodeDeleted`、`NodeDataChanged` 等）执行相应的回调操作。
5. **Watcher 的一次性S特性：**  
   Zookeeper 的 Watcher 是一次性的，即每个 Watcher 只能触发一次事件通知。客户端在接收到通知后，需要重新注册 Watcher，以实现持续监听。
6. **客户端 WatchManager 的作用：**  
   客户端的 WatchManager 负责管理所有注册的 Watcher。当事件发生时，WatchManager 会根B据事件类型和节点路径，找到对应的 Watcher，并执行其回调方法。
