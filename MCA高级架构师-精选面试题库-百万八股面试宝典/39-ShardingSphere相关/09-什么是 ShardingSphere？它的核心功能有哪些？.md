Apache ShardingSphere 是一套开源的分布式数据库中间件生态系统，旨在将传统关系型数据库升级成具备 **分布式 SQL 引擎能力** 的现代化平台。它通过模块化设计提供丰富可插拔功能，帮助开发者 **无需修改业务代码** 即可实现架构能力升级。

### ​ShardingSphere 的核心功能模块

#### 1. **数据分片（Data Sharding）**

ShardingSphere 支持按自定义策略将数据水平分散至多个库和表中。其分片机制包含数据库和表级别的分片支持，并且完全兼容不同数据库类型。

#### 2. **读写分离（Read/Write Splitting）**

支持将写操作路由至主库，将读请求负载分发至多个从库，同时提供事务内读策略与 Hint 强制路由，兼顾一致性与性能需求。

#### 3. **分布式事务（Distributed Transaction）**

提供 XA 和 BASE（柔性事务）双重事务模型支持，实现跨库/跨分片的事务一致性保障。

#### 4. **数据迁移（Data Migration / Scaling）**

支持在线扩容与数据迁移，能够在业务不间断的情况下，重切分和均衡分布数据。

#### 5. **联合查询（Federated Query）**

对于不同数据源的数据支持跨库查询和聚合分析，通过实验性 federation 引擎简化异构数据访问。

#### 6. **数据加密 & 掩码（Data Encryption & Masking）**

支持列级透明加密、脱敏处理，保护敏感数据，并可自定义加密算法。

#### 7. **影子库（Shadow Database）**

用于全链路压测环境，实现对生产数据的隔离访问，确保测试不污染线上。

#### 8. **可观测性（Observability / Governance）**

提供 SQL 审计、访问权限、性能监控和指标采集能力，兼容 Prometheus、Zipkin、SkyWalking 等监控系统。

### 部署方式和架构角色

|  |  |  |  |
| --- | --- | --- | --- |
| **模块** | **访问方式** | **支持语言** | **优势** |
| **ShardingSphere‑JDBC** | 嵌入应用的 JDBC Driver | 仅 Java | 延迟低、零入侵、与 ORM 无缝兼容 |
| **ShardingSphere‑Proxy** | 独立部署的数据库代理层 | 多语言（MySQL/PG 协议） | 对 DBA 友好、语言无关、可集中管理 |
| **ShardingSphere‑Sidecar** | 云原生 Sidecar 模式（开发中） | Kubernetes 环境 | 支持数据库 Mesh 架构管理 |

总结： ShardingSphere 是一套可插拔的数据库增强平台（Database‑Plus），提供数据分片、读写分离、分布式事务、数据加密、影子环境、联邦查询、自动迁移与治理功能。它兼容 Java 和异构语言部署，支持嵌入式 JDBC 和代理模式，帮助企业快速构建高性能、高可扩展性且安全可靠的数据库系统。
