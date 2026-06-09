---
title: Milvus 与 Zilliz 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Milvus
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Milvus 与 Zilliz 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Milvus 与 Zilliz 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 6.1 适合什么场景

Milvus 是开源、云原生、面向大规模向量检索的数据库。Zilliz 是 Milvus 背后的商业托管服务。

适合：

1. 数据量大，想自建或私有化。
2. 需要多种索引类型和较强扩展能力。
3. 对性能、成本、部署形态有较强控制需求。
4. 多团队共享向量检索基础设施。

不适合：

1. 只做几千条文档的小型本地 RAG。
2. 团队没有运维能力却选择复杂分布式部署。
3. 业务更需要强事务和复杂 SQL。

## 6.2 核心概念

| 概念 | 说明 |
|---|---|
| collection | 一组向量数据 |
| schema | 字段定义，包括主键、向量字段、标量字段 |
| partition | collection 内部分区 |
| index | 向量索引，例如 HNSW、IVF、DiskANN |
| metric | 距离度量，例如 L2、IP、COSINE |
| load | 将 collection 或 partition 加载到查询节点 |

## 6.3 Python 基本用法

安装：

```bash
pip install pymilvus
```

创建 collection：

```python
from pymilvus import MilvusClient, DataType

client = MilvusClient(uri="http://localhost:19530")

schema = client.create_schema(
    auto_id=False,
    enable_dynamic_field=True
)

schema.add_field(field_name="id", datatype=DataType.VARCHAR, is_primary=True, max_length=128)
schema.add_field(field_name="doc_id", datatype=DataType.VARCHAR, max_length=128)
schema.add_field(field_name="tenant_id", datatype=DataType.VARCHAR, max_length=128)
schema.add_field(field_name="text", datatype=DataType.VARCHAR, max_length=4096)
schema.add_field(field_name="embedding", datatype=DataType.FLOAT_VECTOR, dim=1536)

client.create_collection(
    collection_name="docs",
    schema=schema
)
```

创建索引：

```python
index_params = client.prepare_index_params()

index_params.add_index(
    field_name="embedding",
    index_type="HNSW",
    metric_type="COSINE",
    params={
        "M": 16,
        "efConstruction": 200
    }
)

client.create_index(
    collection_name="docs",
    index_params=index_params
)
```

写入：

```python
client.insert(
    collection_name="docs",
    data=[
        {
            "id": "doc-1-chunk-1",
            "doc_id": "doc-1",
            "tenant_id": "tenant-a",
            "text": "Spring Boot 自动配置的关键目标是...",
            "embedding": embedding
        }
    ]
)
```

查询：

```python
results = client.search(
    collection_name="docs",
    data=[query_embedding],
    anns_field="embedding",
    search_params={
        "metric_type": "COSINE",
        "params": {"ef": 64}
    },
    filter='tenant_id == "tenant-a"',
    limit=10,
    output_fields=["doc_id", "text", "tenant_id"]
)
```

## 6.4 最佳实践

1. 小规模和评测阶段先用 FLAT 或 HNSW，不要一开始就复杂化。
2. 高召回低延迟在线服务优先评估 HNSW。
3. 超大规模、成本敏感场景评估 IVF、PQ、DiskANN。
4. 高频过滤字段建标量索引，避免向量召回后再大量过滤。
5. 批量写入后统一建索引，通常比边写边频繁建索引更稳定。
6. collection 规划要稳定，频繁变 schema 会增加维护成本。
7. 大规模部署要关注 query node、data node、index node、对象存储和消息队列。
8. 分区适合按明确业务边界拆，例如时间、租户、数据域，不适合无限细分。

## 6.5 常见坑

| 坑 | 解决 |
|---|---|
| collection 没 load 就查 | 查询前加载 collection |
| HNSW 内存高 | 调小 M、评估 IVF 或磁盘索引 |
| 过滤字段没索引 | 给高频标量字段建索引 |
| 分区太多 | 用 metadata filter 替代过细 partition |
| 只测延迟不测召回 | 建立标准问题集和答案集 |
