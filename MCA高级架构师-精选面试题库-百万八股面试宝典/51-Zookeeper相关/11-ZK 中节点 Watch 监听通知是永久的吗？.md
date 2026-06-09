在 Zookeeper 中，节点的 Watch 监听通知并非永久性的，而是一次性的。

​

**工作原理：**  
`getData(path, true)`、`exists(path, true)` 或 `getChildren(path, true)`，Zookeeper 会在该节点发生变化时通知客户端。M

**一次性触发机制：**  
一旦节点发生变化，Zookeeper 会触发一次性通知，并将 Watch 从客户端的监听列表中移除。

**持续监听的实现方式：**  
S如果客户端需要持续监听节点变化，必须在每次收到通知后，重新注册 Watch。

**​**  
从 Zookeeper 3.5.0 版本开始，引入了持久 Watch（Persistent Watch）的概念。持久 Watch 在事件触发后，除非客户端显式取消监听，否则会持续向客户端发送通知，无需每次都重新注册。

**注意事项：**  
持久 Watch 适用于需要长期监听节点变化的场景，但也可能增加服务端的负担。因此，在使用时需要权衡B性能和需求。
