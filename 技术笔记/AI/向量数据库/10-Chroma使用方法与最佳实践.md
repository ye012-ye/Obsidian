---
title: Chroma 使用方法与最佳实践
tags:
  - AI
  - RAG
  - 向量数据库
  - Chroma
created: 2026-05-04
updated: 2026-05-04
up: "[[常用向量数据库使用方法与最佳实践]]"
description: Chroma 使用方法与最佳实践，包括适用场景、核心概念、基本用法、最佳实践和常见坑。
---
# Chroma 使用方法与最佳实践

> [!info] 模块导航
> 上级：[[常用向量数据库使用方法与最佳实践]]；对比选型：[[向量数据库区别优缺点与选型]]。

## 13.1 适合什么场景

Chroma 是面向 AI 应用开发者的向量数据库，简单易用，常用于本地 RAG、原型验证、轻量应用。

适合：

1. 本地开发和 demo。
2. 个人知识库、轻量 RAG。
3. LangChain、LlamaIndex 等框架快速接入。
4. 不想先搭复杂服务。

不适合：

1. 强生产 SLO 的大规模在线服务。
2. 复杂多租户权限。
3. 对索引底层调优要求很高的系统。

## 13.2 核心概念

| 概念 | 说明 |
|---|---|
| collection | 一组 embeddings |
| document | 文本内容 |
| metadata | 结构化字段 |
| embedding function | 自动生成 embedding 的函数 |
| persistent client | 本地持久化 |

## 13.3 Python 基本用法

安装：

```bash
pip install chromadb
```

本地持久化：

```python
import chromadb

client = chromadb.PersistentClient(path="./chroma-data")

collection = client.get_or_create_collection(
    name="docs",
    metadata={"hnsw:space": "cosine"}
)
```

写入：

```python
collection.add(
    ids=["doc-1-chunk-1"],
    embeddings=[embedding],
    documents=["自动配置的关键目标是..."],
    metadatas=[
        {
            "doc_id": "doc-1",
            "tenant_id": "tenant-a",
            "title": "Spring Boot 自动配置"
        }
    ]
)
```

查询：

```python
result = collection.query(
    query_embeddings=[query_embedding],
    n_results=10,
    where={"tenant_id": "tenant-a"},
    include=["documents", "metadatas", "distances"]
)
```

## 13.4 最佳实践

1. 原型阶段很好用，生产前评估并发、备份、权限、监控。
2. 明确持久化目录，不要默认临时路径导致数据丢失。
3. 本地知识库使用稳定 id，方便更新和删除。
4. metadata 字段不要缺少 doc_id 和 source。
5. 如果要长期生产，评估 Chroma Cloud 或迁移到更适合的生产向量库。
6. embedding function 要固定，不要开发中不小心切换模型。

## 13.5 常见坑

| 坑 | 解决 |
|---|---|
| demo 数据丢失 | 使用 PersistentClient 并固定目录 |
| 自动 embedding 模型变化 | 显式指定 embedding function |
| 文档直接整篇入库 | 切 chunk |
| 小项目变大仍不迁移 | 设定规模阈值及时迁移 |
