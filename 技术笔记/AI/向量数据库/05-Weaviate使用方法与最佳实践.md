---
title: Weaviate 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Weaviate
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Weaviate 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Weaviate 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 8.1 适合什么场景

Weaviate 是对象模型明显、支持语义搜索和混合搜索的向量数据库。它很适合希望把“对象、属性、向量、混合检索”放在同一系统中的团队。

适合：

1. 需要 hybrid search，向量和 BM25 一起使用。
2. 需要面向对象的数据建模。
3. 需要和 RAG、生成式搜索、rerank 等能力结合。
4. 想用托管或自托管。

不适合：

1. 只需要 PostgreSQL 内嵌向量能力的小系统。
2. 团队不想学习新的 schema / collection 模型。
3. 已有成熟 Elasticsearch 搜索系统，只想补少量向量字段。

## 8.2 核心概念

| 概念 | 说明 |
|---|---|
| collection | 一类对象集合 |
| object | 一条数据对象 |
| property | 对象字段 |
| vectorizer | 自动向量化模块或外部向量 |
| hybrid search | 向量搜索和 BM25 关键词搜索融合 |

## 8.3 Python 基本用法

安装：

```bash
pip install weaviate-client
```

连接：

```python
import weaviate

client = weaviate.connect_to_local()
```

创建 collection：

```python
from weaviate.classes.config import Configure, Property, DataType

client.collections.create(
    name="Docs",
    properties=[
        Property(name="doc_id", data_type=DataType.TEXT),
        Property(name="tenant_id", data_type=DataType.TEXT),
        Property(name="title", data_type=DataType.TEXT),
        Property(name="text", data_type=DataType.TEXT)
    ],
    vectorizer_config=Configure.Vectorizer.none()
)
```

写入外部向量：

```python
docs = client.collections.get("Docs")

docs.data.insert(
    properties={
        "doc_id": "doc-1",
        "tenant_id": "tenant-a",
        "title": "Spring Boot 自动配置",
        "text": "自动配置的关键目标是..."
    },
    vector=embedding
)
```

向量查询：

```python
from weaviate.classes.query import Filter

response = docs.query.near_vector(
    near_vector=query_embedding,
    limit=10,
    filters=Filter.by_property("tenant_id").equal("tenant-a"),
    return_properties=["doc_id", "title", "text"]
)
```

混合查询：

```python
response = docs.query.hybrid(
    query="Spring Boot 自动配置 ConditionalOnMissingBean",
    vector=query_embedding,
    alpha=0.6,
    limit=10,
    return_properties=["doc_id", "title", "text"]
)
```

`alpha` 越接近 1 越偏向向量，越接近 0 越偏向关键词。

## 8.4 最佳实践

1. 技术文档、代码、API 检索优先考虑 hybrid search。
2. 外部 embedding 模型可控性更强，生产系统建议明确模型版本。
3. collection schema 不要频繁变化。
4. 对权限和租户使用 property filter。
5. 如果用自动 vectorizer，必须明确数据是否允许发送给对应模型服务。
6. hybrid 的 alpha 需要用评测集调，不要只靠感觉。
7. 对长文档做 chunk，不要把整篇文档作为一个 object。

## 8.5 常见坑

| 坑 | 解决 |
|---|---|
| 自动向量化不可控 | 生产中显式管理 embedding |
| hybrid 权重随便设 | 用问题集评估 alpha |
| object 太大 | 先 chunk，再入库 |
| 只看语义不看关键词 | 对专有名词启用 hybrid |
| property 设计混乱 | 入库前定义统一 schema |
