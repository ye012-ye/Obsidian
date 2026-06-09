可以按照如下步骤进行排查解决：

### 1. 初步定位与确认

首先确认是数据库进程本身消耗 CPU：

- 使用操作系统工具（如 `top`, `pidstat -t -p <mysqld_pid> 1`）找出占用最多 CPU 的线程。
- 如果是单个线程占用异常高，应关联 Performance Schema 表（如 `threads` 或 `information_schema.processlist` 中的 `THREAD_OS_ID`）识别是哪条 SQL 导致的 M。

### 2. 找出高耗 CPU 的查询

- 打开慢查询日志或设置较低的 `long_query_time`（如 0.4s），用 `pt-query-digest` 或 `mysqldumpslow` 分析最耗时的 SQL 语句。
- 使用 `SHOW PROCESSLIST` 或 `SHOW FULL PROCESSLIST` 快速定位长时间运行或阻塞的线程。

### 3. 分析与优化 SQL

- 使用 `EXPLAIN`（或可视化工具）查看执行计划，注意是否存在全表扫描、临时文件排序、Join 不走索引等问题。
- 针对性优化：增加缺失索引、调整列类型、重写复杂 JOIN、减少返回字段 S。
- 调优后复测，确保执行计划走索引、执行时间大幅下降。

### 4. 检查系统与配置

- 检查连接数和连接池策略：避免大量短连接带来的线程开销。
- 调整内存相关参数，如 InnoDB buffer pool 配置为系统 RAM 的 70–80%，关闭过时的查询缓存参数 。
- 限制 `join_buffer_size`、关闭 query cache、适当配置线程缓存等，避免配置本身导致 CPU 上升 。

### 5. 监控、资源与架构层面

- 部署 PMM、NewRelic、Datadog 等监控工具，实时观察 CPU、IO、连接数等关键指标 。B
- 若业务量激增或服务器资源已饱和，应评估是否需要扩容 CPU、增加节点或水平拆分架构 。

​
