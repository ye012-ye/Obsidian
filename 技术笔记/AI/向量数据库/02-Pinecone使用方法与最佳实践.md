---
title: Pinecone 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Pinecone
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Pinecone 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Pinecone 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 5.1 适合什么场景

Pinecone 是托管型向量数据库，适合不想自建集群、希望快速上线生产服务的团队。

适合：

1. SaaS、企业知识库、客服 RAG。
2. 需要云托管、少运维。
3. 需要较好的元数据过滤和在线服务能力。
4. 团队更重视交付速度，而不是掌控底层索引实现。

不适合：

1. 必须完全私有化且不能使用外部托管服务。
2. 需要极深度定制底层索引。
3. 成本模型必须完全掌握在自建基础设施里。

## 5.2 核心概念

| 概念 | 说明 |
|---|---|
| index | 向量索引，类似数据库里的库或表 |
| record | 一条向量记录，包含 id、vector、metadata |
| namespace | index 内的逻辑隔离空间，常用于租户或环境隔离 |
| metadata | 结构化过滤字段 |
| dense vector | 稠密向量，适合语义搜索 |
| sparse vector | 稀疏向量，适合关键词或混合搜索 |

## 5.3 Python 基本用法

安装：

```bash
pip install pinecone
```

创建 index 的思路：

```python
from pinecone import Pinecone, ServerlessSpec

pc = Pinecone(api_key="PINECONE_API_KEY")

pc.create_index(
    name="docs",
    dimension=1536,
    metric="cosine",
    spec=ServerlessSpec(
        cloud="aws",
        region="us-east-1"
    )
)
```

写入：

```python
index = pc.Index("docs")

index.upsert(
    namespace="tenant-a",
    vectors=[
        {
            "id": "doc-1-chunk-1",
            "values": embedding,
            "metadata": {
                "doc_id": "doc-1",
                "title": "Spring Boot 自动配置",
                "source": "obsidian",
                "tenant_id": "tenant-a"
            }
        }
    ]
)
```

查询：

```python
result = index.query(
    namespace="tenant-a",
    vector=query_embedding,
    top_k=10,
    include_metadata=True,
    filter={
        "tenant_id": {"$eq": "tenant-a"},
        "source": {"$eq": "obsidian"}
    }
)

for match in result["matches"]:
    print(match["id"], match["score"], match["metadata"]["title"])
```

## 5.4 最佳实践

1. index 维度必须和 embedding 模型维度一致。
2. namespace 不要滥用，租户很多时要评估管理和查询模式。
3. metadata 只放需要过滤、展示、溯源的字段，不要把大段正文都塞进去。
4. 大正文建议放对象存储或主数据库，向量库只存 chunk 文本摘要或引用。
5. 用 `doc_id` 组织删除和重建，不要只能按随机 id 管理。
6. 批量 upsert，避免单条写入导致吞吐低。
7. 明确 topK 和 rerank 策略，不要盲目 topK=3。
8. 对多租户必须加 namespace 或 metadata filter。

## 5.5 常见坑

| 坑 | 解决 |
|---|---|
| 维度不一致 | 创建 index 前固定 embedding 模型 |
| topK 太小 | 先召回更多，再 rerank |
| metadata 缺失 | 入库时强制校验 doc_id、tenant_id、source |
| 只用语义搜索 | 对代码、型号、错误码加入混合检索 |
| 无法回滚模型升级 | 新建 index 或 namespace 做灰度 |
