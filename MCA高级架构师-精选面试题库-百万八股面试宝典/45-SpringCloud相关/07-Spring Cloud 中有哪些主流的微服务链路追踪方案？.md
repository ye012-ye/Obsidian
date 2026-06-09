在 Spring Cloud 环境中，主要的微服务链路追踪方案包括以下几种：

**Zipkin（结合 Spring Cloud Sleuth）**  
通过 Spring Cloud Sleuth 自动生成 Trace 和 Span 信息，并将这些追踪数据发送到 Zipkin 服务。Zipkin 提供集成的存储、查询 API 与 UI，可展示请求流程图及依赖关系图谱。部署简单（通常用单进程方式），适用于中小规模的 Java 微服务系统。

**特点**：入门成本低、与 Sleuth 无缝集成、适合快速搭建与调试环境。  
**适用场景**：轻量级分布式系统或开发测试环境。M

**Jaeger（OpenTracing/OpenTelemetry 支持）**  
Jaeger 最初由 Uber 开发，现在为 CNCF 官方项目，兼容 OpenTracing 与 OpenTelemetry 标准。提供独立的 agent、collector、query 和 UI，多种后端存储选择（如 Elasticsearch 或 Cassandra），并支持自适应采样机制。

**特点**：适合大规模生产环境、支持跨语言、具备高级依赖分析与根因定位能力。  
**适用场景**：复杂微服务架构、Kubernetes/K8s 环境、大流量系统。S

**Apache SkyWalking**  
SkyWalking 是一款既支持链路追踪又提供 APM 能力的开源系统，支持 Java、.NET、Node.js 等多种语言。可与 Spring Cloud Sleuth 集成，也可通过 OpenTelemetry 协议接入，提供服务拓扑图、性能指标和告警功能。

**特点**：功能全面，除了追踪，还支持性能监控、拓扑分析、告警集成；适合多语言混合架构。  
**适用场景**：需要综合可观测性平台、跨语言服务或复杂依赖关系的企业系统。B

**Pinpoint（另一开源方案）**

**特点**：支持调用链与慢接口分析；对 JVM 应用监控较友好。  
**适用场景**：以 Java 为主的大型系统，偏重于慢调用追踪与接口分析需求。

### **对比**

|  |  |  |  |
| --- | --- | --- | --- |
| **方案** | **集成方式** | **优势亮点** | **适用环境** |
| Zipkin | Sleuth + Zipkin | 简单快速、依赖少 | 中小规模 Java 微服务或开发测试 |
| Jaeger | Sleuth/OpenTelemetry | CNCF 标准、高扩展、多语言 | 大型、跨语言、Kubernetes 环境 |
| SkyWalking | Sleuth 或 OTEL | 拓扑+性能监控+告警一体化 | 企业级可观测平台、多语言混合架构 |
| Pinpoint | Sleuth 集成稍复杂 | 深度慢调用分析，支持 JVM 应用 | Java 主导系统、接口调用频繁 |
