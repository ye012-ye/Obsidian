Apache ShardingSphere 是一个分布式数据库中间件生态系统，其三个核心模块分别适用于不同运行环境与使用场景，但共享相同的核心功能组件，包括分库分表、读写分离和分布式事务等。

### 1. ShardingSphere‑JDBC

这是一个轻量级 Java 框架，以 jar 包形式集成在应用层，通过增强 JDBC 层，为开发者提供分片、读写分离、分布式事务等能力。其优点是部署简单、延迟低、与 ORM 框架无缝兼容，不改变原有业务代码逻辑。

工作流程如下：应用通过 `ShardingDataSourceFactory` 或 `MasterSlaveDataSourceFactory` 创建数据源，内部包括分片规则配置。它拦截 SQL，完成解析、路由、重写、调度执行及结果合并过程。

### 2. ShardingSphere‑Proxy

这是一个独立部署的透明代理，以 MySQL/PostgreSQL 协议对外提供数据库接口。适用于多语言环境或需要数据库操作入口给 DBA 使用的场景。客户端无需修改业务代码，只需连接代理层即可享受分片与治理能力。

其内部复用 Sharding-JDBC 的核心逻辑模块进行 SQL 解析、路由重写与执行调度，也集成元数据中心支持高可用部署。适合具备复杂运维需求的 OLAP 或中后台场景。

### 3. ShardingSphere‑Sidecar（尚在开发）

专为云原生环境设计，作为 Kubernetes 或 Mesos 部署的 Sidecar 容器，提供所谓的 **Database Mesh** 功能。它负责拦截数据库访问流量并协同治理与调度，同时借助核心治理平台进行配置管理。适合微服务架构下，追求轻量中心化控制的部署模型。

目前功能尚处于规划阶段，将与 Service Mesh 协作，实现数据访问统一治理、审计、权限控制等功能。
