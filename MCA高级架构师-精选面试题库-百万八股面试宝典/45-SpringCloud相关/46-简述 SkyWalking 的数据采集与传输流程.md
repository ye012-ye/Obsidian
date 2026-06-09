SkyWalking 的架构主要分为四个核心模块：**Probe（探针）**、**Platform Backend（Collector）**、**Storage（存储）** 和 **UI（可视化）**。其中，采集和传输过程集中在前面两个模块之间。

**Probe（探针）** 是部署在应用侧的轻量级代理层，包括 Java Agent、Go SDK、服务网格 Sidecar 等形式。它负责在运行时拦截业务调用，生成 `EntrySpan`, `ExitSpan`, `LocalSpan` 等跟踪数据，同时采集查询延迟、错误率、指标等信息，并封装为统一 SkyWalking Trace/Metric 格式发送出去。

M

采集到的数据通过 **gRPC** 或 **HTTP Restful** 协议被发送至 SkyWalking 的 **Backend Receiver** 模块。Receiver 接收后可对 traces、metrics、logs 和 events 进行缓冲、过滤和初步处理，并将信息推送至 Aggregation 模块进行分析聚合。

**Collector（平台后端）** 是一个模块化可扩展的组件，负责对接入数据进行汇总、分析，并根据 Observability Analysis Language（OAL）定义对数据进行计算、关联和关联度分析，最终驱动存储处理流程。Collector 支持插件化、高并发处理能力，还可与 Satellite 代理结合部署，提升扩缩容与负载均衡效率。

S

分析后的数据通过 **可插拔存储接口** 写入底层存储系统，支持 ElasticSearch、MySQL、TiDB、BanyanDB 等后端。BanyanDB 为 SkyWalking 自研的时序与链路数据库，优化了查询性能与存储结构。

数据最终由 **Web UI** 可视化展示，包括调用链拓扑、服务性能监控、告警规则视图等。同时 SkyWalking 支持将数据推送至外部告警系统或第三方大数据平台进一步消费。

B

整个流程可浓缩为三个阶段：

1. **实时采集**：Probe 在应用侧监听接口调用、资源指标、网络访问日志（包括 eBPF 层面）等原始观测点
2. **传输与聚合**：数据通过 gRPC/HTTP 推送至 Backend Receiver，Collector 聚合分析后准备写入存储或转发。可选多级代理（如 Satellite）进行负载调度与本地缓存增强稳定性。
3. **存储与消费**：持久化至可替换数据库，并通过 UI 展示分析结果，或推送给外部系统进行排行、告警、可视化展示。
