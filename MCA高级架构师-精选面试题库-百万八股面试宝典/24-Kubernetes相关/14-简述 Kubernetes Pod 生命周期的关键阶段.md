**Pod 的定义与作用**  
Pod 是 Kubernetes 中最小的调度与部署单元，它可以包含一个或多个协同运行的容器（如主容器、Init 容器或 Sidecar 容器），这些容器共享网络命名空间、IP 地址和存储卷。由于 Pod 是 Kubernetes 调度的基本对象，对 Pod 进行生命周期管理有助于保持应用的稳定性与一致性。

M

**Pod 生命周期的高层阶段**  
Pod 生命周期可以概括为五个主要阶段（Phase），描述 Pod 从创建到终止的过程：

- **Pending**：资源对象已创建，但尚未调度或容器镜像未拉取完成。通常因资源不足或镜像拉取延迟导致此阶段延长。
- **Running**：Pod 已绑定节点，容器已创建，并至少有一个容器正在运行或启动中。若容器失败重启仍保持此状态。
- **Succeeded**：所有容器均以退出码为 0 正常结束，不会再次重启。通常用于一次性任务 Pod（如 Job）。
- **Failed**：至少有一个容器异常退出（非零退出码）且不再重启时进入该状态。此后 Pod 不再变更阶段，需要控制器或手动重新调度。
- **Unknown**：API Server 无法获取 Pod 状态，可能因节点失联或网络中断导致，此时需要检查节点健康状况。

S

**Init 容器与中间状态**  
对于引用 Init 容器的 Pod，会先执行初始化容器，并在其成功完成后才启动主容器。这一过程可能会遇到 ContainerCreating、ErrImagePull、CrashLoopBackOff 等状态，用于进一步细化调试信息和排错 。

**Pod 条件（Conditions）与容器状态监控**  
除了 phase，PodStatus 中还包含 Conditions，如 PodScheduled、Initialized、Ready、ContainersReady 等，用于精确反映调度、初始化、运行准备等状态。容器本身也具有 Waiting、Running、Terminated 等内部状态，有助于判断容器具体运行情况。

**优雅终止与清理流程**  
当 Pod 被删除时，它首先进入 Terminating 状态（这不是正式 Phase）。Kubernetes 会发送 SIGTERM 信号给容器，给予默认 30 秒的 graceful timeout（可通过 `terminationGracePeriodSeconds` 自定义）。执行 preStop Hook 后若容器依然未退出，将被强制发送 SIGKILL。完成后清理 Pod 资源，包括释放 IP、卷挂载和从 API Server 中删除相关对象。

​

**总结**

B
