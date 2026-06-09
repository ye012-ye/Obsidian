在 Spring Cloud 微服务架构中，我们常用 **Prometheus + Grafana** 组合来实现系统级监控与告警，具体设计如下：

M

### 一、监控体系架构

我们通过 **Micrometer + Spring Boot Actuator** 打点并暴露指标端点，每个微服务都会提供 `/actuator/prometheus` 接口供 Prometheus 定期抓取。Prometheus 使用拉模型（Pull）收集时间序列数据，存储在自身 TSDB 中，并支持多维标签、PromQL 查询等强大功能。

Grafana 作为可视化层，通过配置 Prometheus 数据源，构建业务视角的监控仪表板，包括但不限于 QPS、响应时间、资源使用、错误率等关键指标。

这套组合适合在 Kubernetes、Docker Compose 或 VM 环境中部署，可作为微服务集群的统一监控平台。

S

### 二、核心监控内容

- **业务指标**：接口请求数、成功率、平均耗时、错误比例等。
- **容器/系统指标**：CPU、内存、GC、线程池状态、磁盘 I/O 使用率等。
- **服务健康指标**：利用 Spring Boot `health`、`info` 等 Actuator 接口，Prometheus 也可抓取相关状态。

B

### 三、告警机制设计

监控系统中 Prometheus 内置 **Alertmanager**，通过 PromQL 定义告警规则（如延迟峰值、错误率突高、资源压力），支持告警聚合、分级抑制与静默设置等功能。

当 Prometheus 检测到告警条件满足时，会将通知发送至 Alertmanager，再根据配置推送到团队常用渠道，如邮件、Slack 或 PagerDuty。Grafana 也可配置自身告警规则（当 Prometheus 异常时可触发备份告警）以提高告警可靠性。

### 总结

Prometheus + Grafana 搭建的监控告警体系，适用于 Spring Cloud 微服务环境。它提供精细的指标抓取、强大的查询能力、稳定的可视化展示，并支持灵活的告警机制，是团队对系统稳定性、性能可观测性进行有效管控的核心方式。
