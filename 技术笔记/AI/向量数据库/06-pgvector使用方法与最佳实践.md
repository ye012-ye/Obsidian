---
title: PostgreSQL pgvector 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - pgvector
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: PostgreSQL pgvector 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# PostgreSQL pgvector 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 9.1 适合什么场景

pgvector 是 PostgreSQL 的向量扩展。它适合已经使用 PostgreSQL，并且数据规模、QPS、延迟要求还在 PostgreSQL 可承受范围内的系统。

适合：

1. 业务数据本来就在 PostgreSQL。
2. 需要 SQL、事务、JOIN、权限和向量搜索结合。
3. 中小规模 RAG、后台检索、企业内部系统。
4. 不想额外引入独立向量数据库。

不适合：

1. 十亿级向量和极高 QPS 在线服务。
2. 需要独立扩展向量检索节点。
3. 复杂多模态和大规模 ANN 专项优化。

## 9.2 核心概念

| 概念 | 说明 |
|---|---|
| `vector(n)` | pgvector 向量字段类型 |
| HNSW index | 图索引，查询性能和召回通常较好 |
| IVFFlat index | 聚类索引，构建较快，内存较省，需要训练数据 |
| distance operator | 距离操作符，例如 `<->`、`<=>`、`<#>` |
| SQL filter | 直接使用 `WHERE` 过滤业务字段 |

## 9.3 SQL 基本用法

启用扩展：

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

建表：

```sql
CREATE TABLE document_chunks (
    id bigserial PRIMARY KEY,
    doc_id text NOT NULL,
    tenant_id text NOT NULL,
    title text,
    content text NOT NULL,
    embedding vector(1536),
    created_at timestamptz DEFAULT now()
);
```

插入：

```sql
INSERT INTO document_chunks (
    doc_id,
    tenant_id,
    title,
    content,
    embedding
) VALUES (
    'doc-1',
    'tenant-a',
    'Spring Boot 自动配置',
    '自动配置的关键目标是...',
    '[0.01,0.02,0.03]'::vector
);
```

创建 HNSW 索引：

```sql
CREATE INDEX document_chunks_embedding_hnsw_idx
ON document_chunks
USING hnsw (embedding vector_cosine_ops);
```

查询：

```sql
SELECT
    id,
    doc_id,
    title,
    content,
    1 - (embedding <=> '[0.01,0.02,0.03]'::vector) AS score
FROM document_chunks
WHERE tenant_id = 'tenant-a'
ORDER BY embedding <=> '[0.01,0.02,0.03]'::vector
LIMIT 10;
```

IVFFlat 索引：

```sql
CREATE INDEX document_chunks_embedding_ivfflat_idx
ON document_chunks
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

查询时调整 probes：

```sql
SET ivfflat.probes = 10;
```

## 9.4 最佳实践

1. 小数据先不建 ANN 索引，直接精确搜索作为质量基线。
2. 数据量上来后优先评估 HNSW。
3. `tenant_id`、`doc_id`、`created_at` 等结构化字段使用普通 PostgreSQL 索引。
4. 向量字段不要和大文本、JSON 大字段一起频繁全表扫描。
5. 对多租户可以使用分区表或普通索引，视租户数量和数据量决定。
6. 用事务保证业务数据和向量记录同步写入。
7. 定期 `VACUUM`、`ANALYZE`，关注索引膨胀。
8. 复杂 RAG 可先用 pgvector 起步，规模扩大后再迁移到专用向量库。

## 9.5 常见坑

| 坑 | 解决 |
|---|---|
| 把 pgvector 当无限扩展向量集群 | 明确 PostgreSQL 的单库容量和 QPS 边界 |
| 没有结构化索引 | 给 tenant_id、doc_id、time 建 B-tree 索引 |
| IVFFlat recall 差 | 调整 lists/probes 或换 HNSW |
| 模型升级覆盖旧向量 | 新建字段或新表灰度 |
| 只看 SQL 能跑 | 还要看 explain、延迟、召回率 |
