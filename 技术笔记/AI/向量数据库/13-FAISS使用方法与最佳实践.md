---
title: FAISS 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - FAISS
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: FAISS 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# FAISS 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 16.1 先明确：FAISS 不是完整数据库

FAISS 是 Meta 开源的高性能相似度搜索库。它非常强，但它不是完整意义上的数据库。

它擅长：

1. 高性能向量索引。
2. 本地向量检索。
3. GPU 加速。
4. 研究、评测、离线召回。
5. 自己封装向量服务。

它不直接提供完整数据库能力：

1. 没有内建复杂 metadata 过滤。
2. 没有数据库式权限、备份、复制、事务。
3. 需要自己管理 id 到原文的映射。
4. 需要自己持久化和服务化。

## 16.2 Python 基本用法

安装：

```bash
pip install faiss-cpu
```

创建精确索引：

```python
import faiss
import numpy as np

dim = 1536
index = faiss.IndexFlatIP(dim)

vectors = np.array(embeddings, dtype="float32")
faiss.normalize_L2(vectors)

index.add(vectors)
```

查询：

```python
query = np.array([query_embedding], dtype="float32")
faiss.normalize_L2(query)

scores, ids = index.search(query, k=10)
```

HNSW 示例：

```python
index = faiss.IndexHNSWFlat(dim, 32)
index.hnsw.efConstruction = 200
index.hnsw.efSearch = 64
index.add(vectors)
```

持久化：

```python
faiss.write_index(index, "docs.faiss")
index = faiss.read_index("docs.faiss")
```

## 16.3 最佳实践

1. 用 FAISS 做召回质量评测基线很合适。
2. 生产服务要自己补 metadata store、权限、更新、删除、备份。
3. 大规模使用 IVF/PQ 前先建立精确检索基线。
4. cosine 相似度常用做法是向量归一化后用内积。
5. id 映射要稳定保存，不能只保存 FAISS index。
6. 离线构建索引、在线只读查询是更稳的模式。

## 16.4 常见坑

| 坑 | 解决 |
|---|---|
| 当成数据库 | 自己补主数据、metadata、服务化 |
| id 映射丢失 | 保存 id map |
| 向量没归一化 | cosine 场景先 normalize |
| 动态更新复杂 | 评估是否换真正向量数据库 |
| 没有过滤能力 | 先过滤候选或外部系统辅助 |
