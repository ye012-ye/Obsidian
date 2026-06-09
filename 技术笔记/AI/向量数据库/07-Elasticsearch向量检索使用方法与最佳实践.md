---
title: Elasticsearch 向量检索使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Elasticsearch
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Elasticsearch 向量检索使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Elasticsearch 向量检索使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 10.1 适合什么场景

Elasticsearch 适合已经有搜索系统，并希望把语义向量能力加入现有关键词检索、过滤、聚合、日志检索体系的团队。

适合：

1. 原本就用 Elasticsearch 做全文检索。
2. 需要 BM25 + vector 混合检索。
3. 需要搜索相关的过滤、聚合、排序、权限。
4. 日志、商品、文档、知识库搜索统一在 ES 中。

不适合：

1. 只需要纯向量检索，且不需要全文搜索生态。
2. 不想承担 ES 集群运维复杂度。
3. 数据模型更适合关系型事务。

## 10.2 核心概念

| 概念 | 说明 |
|---|---|
| index | ES 索引 |
| document | 文档记录 |
| `dense_vector` | 存储 dense embedding 的字段类型 |
| kNN search | 最近邻向量检索 |
| BM25 | 传统关键词相关性 |
| hybrid search | 关键词和向量结果融合 |

## 10.3 基本用法

创建 mapping：

```json
PUT docs
{
  "mappings": {
    "properties": {
      "doc_id": { "type": "keyword" },
      "tenant_id": { "type": "keyword" },
      "title": { "type": "text" },
      "content": { "type": "text" },
      "embedding": {
        "type": "dense_vector",
        "dims": 1536,
        "similarity": "cosine",
        "index": true
      }
    }
  }
}
```

写入：

```json
POST docs/_doc/doc-1-chunk-1
{
  "doc_id": "doc-1",
  "tenant_id": "tenant-a",
  "title": "Spring Boot 自动配置",
  "content": "自动配置的关键目标是...",
  "embedding": [0.01, 0.02, 0.03]
}
```

kNN 查询：

```json
POST docs/_search
{
  "knn": {
    "field": "embedding",
    "query_vector": [0.01, 0.02, 0.03],
    "k": 10,
    "num_candidates": 100,
    "filter": {
      "term": {
        "tenant_id": "tenant-a"
      }
    }
  },
  "_source": ["doc_id", "title", "content", "tenant_id"]
}
```

混合检索思路：

```json
POST docs/_search
{
  "query": {
    "match": {
      "content": "Spring Boot 自动配置 ConditionalOnMissingBean"
    }
  },
  "knn": {
    "field": "embedding",
    "query_vector": [0.01, 0.02, 0.03],
    "k": 20,
    "num_candidates": 100
  }
}
```

实际生产中通常还会做重排或使用 rank 融合策略。

## 10.4 最佳实践

1. 如果已有 ES 搜索系统，优先评估直接加 `dense_vector`。
2. 关键词强相关场景使用 hybrid，不要只靠向量。
3. `num_candidates` 影响召回和延迟，需要评测调参。
4. 对权限字段使用 keyword filter。
5. 大字段 `_source` 返回要控制，避免网络开销太大。
6. 分片数量要根据数据量和 QPS 规划，不能只靠默认值。
7. 对日志和搜索混合集群，要隔离冷热数据和高负载查询。

## 10.5 常见坑

| 坑 | 解决 |
|---|---|
| ES 已经很重还继续塞所有向量 | 评估独立向量库或冷热分离 |
| `num_candidates` 太小 | 增大候选数再看召回 |
| 只用 vector 忽略 BM25 | 混合检索 |
| mapping 后期频繁改 | 前期规划字段和维度 |
| 返回全文过多 | 控制 `_source` 字段 |
