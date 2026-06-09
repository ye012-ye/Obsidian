Kubernetes 的工作流程涉及多个组件的协同工作，确保容器化应用的高效部署与管理。以下是其核心流程的详细解析：

M

1. **用户提交部署请求**  
   用户通过 `kubectl` 或其他客户端工具，提交包含应用配置的 YAML 文件（如 `Deployment`）至 Kubernetes 集群的 API Server。该文件定义了所需的应用状态，包括容器镜像、环境变量、资源限制等。
2. **API Server 处理请求**  
   API Server 接收到请求后，进行认证、授权、准入控制等操作，确保请求的合法性。随后，它将资源对象存储到集群的数据库 `etcd` 中，作为集群当前状态的记录。
3. **Controller Manager 监控资源变化**  
   Controller Manager 通过 List-Watch 机制，持续监控 `etcd` 中的资源对象。当发现资源状态与期望不符时（如缺少 Pod 副本），会启动相应的控制器进行修正。
4. **ReplicaSet 创建 Pod 实例**  
   对于 Deployment，ReplicaSet 控制器会根据设定的副本数，检查当前运行的 Pod 数量。如果实际数量少于期望值，ReplicaSet 会创建新的 Pod 实例以满足需求。
5. **调度器（Scheduler）分配节点**  
   Scheduler 监控 `etcd` 中的 Pod 状态，发现尚未被调度的 Pod 时，会根据预定的调度策略（如资源需求、亲和性、反亲和性等），选择一个合适的节点（Node）进行部署。调度结果会更新到 `etcd` 中。
6. **Kubelet 管理 Pod 生命周期**  
   Kubelet 运行在每个节点上，负责管理该节点上 Pod 的生命周期。它定期与 API Server 通信，获取 Pod 的最新状态，并确保容器按照预期运行。如果发现 Pod 不健康或未运行，Kubelet 会尝试重启容器或报告异常。
7. **网络代理（kube-proxy）实现服务访问**  
   kube-proxy 运行在每个节点上，负责实现服务的负载均衡和网络代理。它根据 Service 的定义，维护虚拟 IP 和实际 Pod 之间的映射，确保请求能够正确路由到目标 Pod。
8. **集群状态同步与自我修复**  
   Kubernetes 通过上述组件的协作，持续监控和维护集群的期望状态。即使在节点故障、Pod 崩溃等情况下，系统也能自动进行恢复，确保应用的高可用性和稳定性。

S
