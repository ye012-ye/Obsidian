---
title: OpenSearch k-NN 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - OpenSearch
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: OpenSearch k-NN 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# OpenSearch k-NN 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 11.1 适合什么场景

OpenSearch 是 Elasticsearch 分叉后的开源搜索引擎，k-NN 插件提供向量检索能力。它适合偏开源、自托管、AWS OpenSearch 生态或已有 OpenSearch 搜索系统的团队。

适合：

1. 已经使用 OpenSearch。
2. 需要全文检索 + 向量检索。
3. 需要开源搜索引擎生态。
4. AWS OpenSearch Service 场景。

不适合：

1. 不需要搜索引擎，只需要简单 RAG。
2. 团队没有搜索集群调优经验。
3. 强事务和复杂 OLTP 场景。

## 11.2 基本用法

创建 index：

```json
PUT docs
{
  "settings": {
    "index": {
      "knn": true
    }
  },
  "mappings": {
    "properties": {
      "doc_id": { "type": "keyword" },
      "tenant_id": { "type": "keyword" },
      "content": { "type": "text" },
      "embedding": {
        "type": "knn_vector",
        "dimension": 1536,
        "method": {
          "name": "hnsw",
          "space_type": "cosinesimil",
          "engine": "faiss"
        }
      }
    }
  }
}
```

查询：

```json
POST docs/_search
{
  "size": 10,
  "query": {
    "knn": {
      "embedding": {
        "vector": [0.01, 0.02, 0.03],
        "k": 10
      }
    }
  }
}
```

带过滤的典型思路：

```json
POST docs/_search
{
  "size": 10,
  "query": {
    "bool": {
      "filter": [
        { "term": { "tenant_id": "tenant-a" } }
      ],
      "must": [
        {
          "knn": {
            "embedding": {
              "vector": [0.01, 0.02, 0.03],
              "k": 10
            }
          }
        }
      ]
    }
  }
}
```

## 11.3 最佳实践

1. 如果已经用 OpenSearch，向量检索可以作为搜索体系增强。
2. 先明确 engine、space_type、HNSW 参数。
3. 对关键词和语义都重要的业务，做 hybrid。
4. 观察 JVM、堆内存、段合并、查询延迟。
5. AWS 托管场景要核对实例类型、插件版本和功能限制。

## 11.4 常见坑

| 坑 | 解决 |
|---|---|
| 当作简单 KV 向量库使用 | 如果不需要搜索引擎生态，选更轻的库 |
| HNSW 参数默认不调 | 用评测集调召回和延迟 |
| 集群资源不足 | 分片、节点、内存单独规划 |
| ES/OpenSearch API 混用 | 核对各自版本文档 |
