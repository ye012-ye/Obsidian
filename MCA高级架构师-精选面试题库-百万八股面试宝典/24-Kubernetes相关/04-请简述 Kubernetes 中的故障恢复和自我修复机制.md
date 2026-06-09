Kubernetes 提供了强大的故障恢复和自我修复机制，确保容器化应用在面对各种故障时能够自动恢复并维持高可用性。

M

**故障恢复机制**

Kubernetes 的故障恢复机制主要体现在以下几个方面：

- **Pod 重启策略**：Kubernetes 通过 Pod 的 `restartPolicy` 字段来定义容器的重启行为。常见的策略包括：

- `Always`：无论容器退出状态如何，Kubernetes 都会重启容器。
- `OnFailure`：仅当容器以非零状态码退出时才重启。
- `Never`：容器退出后不重启。

- **Pod 副本控制器**：如 Deployment、StatefulSet 和 DaemonSet 等控制器会确保指定数量的 Pod 副本始终运行。当 Pod 失败或被删除时，控制器会自动创建新的 Pod 实例以替代。
- **节点故障恢复**：当节点不可用时，Kubernetes 会将该节点上的 Pod 标记为不可调度，并在其他健康节点上重新调度这些 Pod，以确保服务的连续性。

S

**自我修复机制**

Kubernetes 的自我修复机制通过以下方式实现：

- **健康检查（Probes）**：Kubernetes 提供了三种类型的健康检查：

- **Liveness Probe**：检测容器是否处于运行状态。如果失败，Kubernetes 会重启容器。
- **Readiness Probe**：检测容器是否准备好接受流量。如果失败，Kubernetes 会将该容器从服务的 Endpoints 中移除，直到容器恢复正常。
- **Startup Probe**：用于检测容器是否成功启动。适用于启动时间较长的应用，防止在初始化期间被误判为失败。

- **Pod 生命周期管理**：Kubernetes 会根据 Pod 的状态自动采取措施，例如当 Pod 处于 `CrashLoopBackOff` 状态时，Kubernetes 会应用指数退避策略，延迟重启容器，以避免系统过载。
- **节点自动修复**：Kubernetes 支持节点自动修复功能，例如使用 Kured 等工具自动重启需要更新的节点，确保节点始终处于最新和健康的状态。

B
