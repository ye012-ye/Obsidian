在 Kubernetes 中，滚动升级（Rolling Update）和回滚（Rollback）是确保应用程序平滑过渡和高可用性的关键机制。

M

**滚动升级：**  
Kubernetes 的 Deployment 控制器默认采用滚动升级策略。

在滚动升级过程中，Kubernetes 会逐步替换旧版本的 Pod 实例为新版本。

具体而言，Kubernetes 会根据 Deployment 的配置，逐步减少旧版本 Pod 的数量，并增加新版本 Pod 的数量，直到所有 Pod 都更新为新版本。

这种方式确保了在升级过程中，始终有一定数量的 Pod 可用，从而实现无缝升级，避免了服务中断。

S

**回滚机制：**  
Kubernetes 的 Deployment 控制器会保留历史版本的 ReplicaSet。

当新版本出现问题时，可以通过以下命令进行回滚：

```bash
kubectl rollout undo deployment [deployment-name]
```

此外，还可以指定回滚到特定的版本：

```bash
kubectl rollout undo deployment [deployment-name] --to-revision=[revision-number]
```

这种机制使得应用程序能够快速恢复到稳定状态，减少了因版本问题导致的服务中断时间。

B
