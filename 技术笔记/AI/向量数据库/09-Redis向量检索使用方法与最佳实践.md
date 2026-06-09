---
title: Redis Vector Search 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Redis
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Redis Vector Search 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Redis Vector Search 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 12.1 适合什么场景

Redis 的向量检索依赖 Redis Query Engine / RediSearch 相关能力。它适合需要低延迟、数据规模中等、已有 Redis 生态的场景。

适合：

1. 低延迟在线推荐或实时检索。
2. Redis 已经是核心基础设施。
3. 需要向量和 metadata 存在 Hash 或 JSON 中。
4. 数据量不是超大，或者可以接受 Redis 的内存成本。

不适合：

1. 超大规模低成本冷数据向量存储。
2. 复杂长期归档和大规模离线分析。
3. 团队不愿承受 Redis 内存成本。

## 12.2 核心概念

| 概念 | 说明 |
|---|---|
| Hash / JSON | 存储向量和 metadata |
| vector index | 对向量字段建立二级索引 |
| FLAT | 精确暴力搜索 |
| HNSW | 近似图索引 |
| SVS-VAMANA | 新的可扩展向量索引方向，具体能力需看版本 |
| FT.SEARCH | 查询入口 |

## 12.3 基本用法

创建 HNSW 索引示例：

```bash
FT.CREATE docs_idx ON HASH PREFIX 1 doc: SCHEMA \
  tenant_id TAG \
  title TEXT \
  content TEXT \
  embedding VECTOR HNSW 6 TYPE FLOAT32 DIM 1536 DISTANCE_METRIC COSINE
```

写入：

```bash
HSET doc:1 \
  tenant_id tenant-a \
  title "Spring Boot 自动配置" \
  content "自动配置的关键目标是..." \
  embedding "<binary-float32-vector>"
```

查询：

```bash
FT.SEARCH docs_idx \
  "(@tenant_id:{tenant-a})=>[KNN 10 @embedding $vec AS score]" \
  PARAMS 2 vec "<binary-float32-query-vector>" \
  SORTBY score \
  RETURN 4 title content tenant_id score \
  DIALECT 2
```

Python 中通常要把 `float32` 数组转成 bytes：

```python
import numpy as np

vector_bytes = np.array(embedding, dtype=np.float32).tobytes()
```

## 12.4 最佳实践

1. Redis 更适合热数据和低延迟场景，不适合无脑存全部冷数据。
2. 估算向量内存：`条数 * 维度 * 4 bytes`，再加索引开销。
3. 小数据或强精确可用 FLAT，大数据在线查询优先 HNSW。
4. metadata 字段使用 TAG / NUMERIC / TEXT 合理建索引。
5. 大规模写入要批量 pipeline。
6. 对过期数据可以利用 TTL，但要评估索引清理行为。
7. 不要把 Redis 当唯一长期数据源，重要原文要有主存储。

## 12.5 常见坑

| 坑 | 解决 |
|---|---|
| 忽略内存成本 | 入库前估算向量和索引内存 |
| 向量格式错误 | 使用 float32 bytes |
| TAG/TEXT 类型乱用 | 精确过滤用 TAG，全文用 TEXT |
| 冷热不分 | Redis 放热向量，冷数据放对象存储或专用库 |
| 没有主数据备份 | 原文和业务数据保存在主库 |
