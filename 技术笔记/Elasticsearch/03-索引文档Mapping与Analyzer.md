---
title: 索引、文档、Mapping 与 Analyzer
tags:
  - Java
  - Elasticsearch
  - Mapping
  - Analyzer
created: 2026-06-10
up: "[[00-MOC-Java-ES从0基础到大神]]"
description: 理解 index、document、mapping、settings、text、keyword、analyzer 和 doc_values。
---

# 索引、文档、Mapping 与 Analyzer

> [!tip] 本章目标
> 你要能看懂一个索引结构，并知道字段类型一旦设计错，后面会有多麻烦。

## 核心概念

| 概念 | 含义 | 类比 |
|---|---|---|
| index | 一类文档的集合 | 商品书架 |
| document | 一条 JSON 数据 | 一本书 |
| field | 文档里的字段 | 书名、作者、价格 |
| mapping | 字段类型和索引规则 | 图书编目规则 |
| settings | 分片、副本、刷新间隔等配置 | 图书馆运营参数 |
| shard | 索引的物理分片 | 多个仓库 |
| replica | 分片副本 | 备份仓库 |

官方文档把 index 的核心组成归纳为 documents、mappings、settings；ES 在背后会把索引切成 shards 并分布到节点上。

## text 和 keyword

| 类型 | 是否分词 | 适合 |
|---|---:|---|
| `text` | 是 | 标题、正文、描述 |
| `keyword` | 否 | ID、状态、分类、标签、枚举、精确筛选 |

> [!example] 商品字段设计
> `name` 用 `text` 做全文搜索，同时加一个 `name.keyword` 用于精确排序或聚合。  
> `brand`、`category`、`status` 通常用 `keyword`。  
> `price` 用数值类型。  
> `createdAt` 用 `date`。

## Analyzer 是什么

Analyzer 负责把文本变成 token。比如：

```text
Java Elasticsearch 教学
```

可能被拆成：

```text
java, elasticsearch, 教学
```

官方文档强调：`analyzer` 只支持 `text` 字段；如果没有单独配置 `search_analyzer`，索引和搜索会使用同一个 analyzer。官方也建议上线前测试 analyzer。

> [!warning] Analyzer 不是随便改的
> `analyzer` 不能直接在已有字段上更新。字段分词规则变了，通常意味着要新建索引并重建数据。

## doc_values 是什么

倒排索引用来搜索，`doc_values` 更像列式存储，用来排序、聚合、脚本读取字段值。官方文档说明它在文档写入时构建，适合高效访问字段值。

> [!info] 一句话
> 搜索靠倒排索引，排序聚合靠 `doc_values`。所以 `text` 字段通常不直接排序聚合，`keyword`、数值、日期字段才常用于排序聚合。

## 创建索引示例

```java
client.indices().create(c -> c
        .index("products_v1")
        .mappings(m -> m
                .properties("id", p -> p.keyword(k -> k))
                .properties("name", p -> p.text(t -> t
                        .analyzer("standard")
                        .fields("keyword", f -> f.keyword(k -> k.ignoreAbove(256)))
                ))
                .properties("brand", p -> p.keyword(k -> k))
                .properties("category", p -> p.keyword(k -> k))
                .properties("price", p -> p.double_(d -> d))
                .properties("stock", p -> p.integer(i -> i))
                .properties("createdAt", p -> p.date(d -> d))
        )
);
```

## Mapping 设计口诀

> [!success] 字段设计 6 问
> 1. 这个字段要全文搜索吗？要就 `text`。  
> 2. 这个字段要精确过滤吗？要就 `keyword`。  
> 3. 这个字段要排序或聚合吗？用 `keyword`、数值或日期。  
> 4. 这个字段会不会变成无限动态 key？会就小心 mapping 爆炸。  
> 5. 这个字段需要中文分词吗？需要就规划 analyzer。  
> 6. 这个字段未来可能重做规则吗？用版本化索引和别名兜底。

## 本章小结

> [!danger] 生产红线
> Mapping 是 ES 项目的地基。地基歪了，业务越写越痛。上线前一定要评审字段类型、分词、排序聚合字段、动态字段策略。

