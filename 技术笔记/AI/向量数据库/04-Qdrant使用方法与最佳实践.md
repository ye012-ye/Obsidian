---
title: Qdrant 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Qdrant
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Qdrant 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Qdrant 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 7.1 适合什么场景

Qdrant 是偏工程友好的开源向量数据库，payload 过滤能力清晰，API 简洁，适合 RAG、推荐、语义搜索。

适合：

1. 需要自托管或托管均可。
2. 需要强 metadata / payload 过滤。
3. 需要 named vectors，多向量字段。
4. 想快速搭建生产可用向量服务。

不适合：

1. 已经高度绑定 PostgreSQL 或 Elasticsearch，不想引入新组件。
2. 需要复杂 SQL 分析和事务。
3. 只做极小 demo，Chroma 或 FAISS 更轻。

## 7.2 核心概念

| 概念 | 说明 |
|---|---|
| collection | 点的集合 |
| point | 一条记录，包含 id、vector、payload |
| payload | metadata 字段，可过滤 |
| named vectors | 一个 point 中存多个向量 |
| payload index | 对 payload 字段建索引以提升过滤性能 |

## 7.3 Python 基本用法

安装：

```bash
pip install qdrant-client
```

创建 collection：

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

client = QdrantClient(url="http://localhost:6333")

client.create_collection(
    collection_name="docs",
    vectors_config=VectorParams(
        size=1536,
        distance=Distance.COSINE
    )
)
```

写入：

```python
from qdrant_client.models import PointStruct

client.upsert(
    collection_name="docs",
    points=[
        PointStruct(
            id="doc-1-chunk-1",
            vector=embedding,
            payload={
                "doc_id": "doc-1",
                "tenant_id": "tenant-a",
                "title": "Spring Boot 自动配置",
                "text": "自动配置的关键目标是..."
            }
        )
    ]
)
```

过滤查询：

```python
from qdrant_client.models import Filter, FieldCondition, MatchValue

hits = client.query_points(
    collection_name="docs",
    query=query_embedding,
    query_filter=Filter(
        must=[
            FieldCondition(
                key="tenant_id",
                match=MatchValue(value="tenant-a")
            )
        ]
    ),
    limit=10,
    with_payload=True
)
```

创建 payload index：

```python
from qdrant_client.models import PayloadSchemaType

client.create_payload_index(
    collection_name="docs",
    field_name="tenant_id",
    field_schema=PayloadSchemaType.KEYWORD
)
```

## 7.4 最佳实践

1. 把权限、租户、文档类型、时间放 payload。
2. 高频过滤字段建 payload index。
3. 多模态或多模型场景使用 named vectors，而不是混在一个向量字段里。
4. 使用 deterministic id，例如 `doc_id + chunk_no`，方便幂等更新。
5. 删除文档时按 `doc_id` filter 删除所有 chunk。
6. 查询时一定明确 `with_payload` 和 `with_vectors`，避免返回不必要数据。
7. 本地开发可以用单节点，生产要规划快照、备份、复制和监控。

## 7.5 常见坑

| 坑 | 解决 |
|---|---|
| payload 只存 text | 补齐 tenant_id、doc_id、source、time |
| 没建 payload index | 高频过滤字段建索引 |
| id 随机导致更新困难 | 使用稳定 id |
| topK 过小 | 召回多一些再 rerank |
| 多向量混用 | 使用 named vectors |
