---
title: MongoDB Atlas Vector Search 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - MongoDB
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: MongoDB Atlas Vector Search 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# MongoDB Atlas Vector Search 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 15.1 适合什么场景

MongoDB Atlas Vector Search 适合业务主数据本来就在 MongoDB Atlas，并希望在同一个文档数据库中增加向量搜索。

适合：

1. 应用已经使用 MongoDB Atlas。
2. 需要向量和文档字段放在一起。
3. 希望用 aggregation pipeline 组合业务过滤和向量搜索。
4. 推荐、语义搜索、RAG 文档检索。

不适合：

1. 不使用 MongoDB Atlas，且不想引入 Atlas。
2. 需要完全自建开源向量数据库。
3. 纯向量超大规模专项服务。

## 15.2 核心概念

| 概念 | 说明 |
|---|---|
| collection | MongoDB 集合 |
| embedding field | 文档中的向量字段 |
| vector search index | Atlas 上单独创建的向量搜索索引 |
| `$vectorSearch` | 聚合管道中的向量搜索阶段 |
| filter | 向量搜索中的结构化过滤 |

## 15.3 基本用法

文档结构：

```json
{
  "_id": "doc-1-chunk-1",
  "doc_id": "doc-1",
  "tenant_id": "tenant-a",
  "title": "Spring Boot 自动配置",
  "content": "自动配置的关键目标是...",
  "embedding": [0.01, 0.02, 0.03]
}
```

聚合查询：

```javascript
db.document_chunks.aggregate([
  {
    $vectorSearch: {
      index: "embedding_index",
      path: "embedding",
      queryVector: queryEmbedding,
      numCandidates: 100,
      limit: 10,
      filter: {
        tenant_id: "tenant-a"
      }
    }
  },
  {
    $project: {
      doc_id: 1,
      title: 1,
      content: 1,
      score: { $meta: "vectorSearchScore" }
    }
  }
])
```

## 15.4 最佳实践

1. 业务数据已经在 MongoDB 时优先考虑，避免双写复杂度。
2. `numCandidates` 需要评估，太小影响召回，太大影响延迟。
3. 对租户、权限、类型字段建立合适的普通索引和 vector filter。
4. 文档字段和向量字段同库后，要更注意文档大小和更新频率。
5. 模型升级建议新增 embedding 字段或新 collection。
6. 权限过滤必须进入 `$vectorSearch.filter`。

## 15.5 常见坑

| 坑 | 解决 |
|---|---|
| 以为普通索引就是 vector index | 在 Atlas Search 中单独创建向量索引 |
| numCandidates 随便设 | 用召回评测调参 |
| 大文档整篇向量化 | 切 chunk 存储 |
| 多租户只在应用层过滤 | 放入 `$vectorSearch.filter` |
