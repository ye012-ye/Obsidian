---
title: Query DSL 搜索从入门到进阶
tags:
  - Java
  - Elasticsearch
  - QueryDSL
created: 2026-06-10
up: "[[00-MOC-Java-ES从0基础到大神]]"
description: 掌握 match、term、range、bool、multi_match、filter 与 query 的区别。
---

# Query DSL 搜索从入门到进阶

> [!tip] 本章目标
> 你要能把“用户想找什么”翻译成 ES Query DSL，再用 Java Client 写出来。

## query 和 filter

| 类型 | 是否算分 | 适合 |
|---|---:|---|
| query | 是 | 关键词相关性搜索 |
| filter | 否 | 状态、分类、价格区间、权限过滤 |

> [!success] 经验规则
> 会影响“谁排前面”的条件放 query；只决定“要不要出现”的条件放 filter。

## match：全文搜索

```java
var response = client.search(s -> s
        .index("products_v1")
        .query(q -> q.match(m -> m
                .field("name")
                .query("Java ES 实战")
        )), ProductDoc.class);
```

`match` 会走字段 analyzer，适合 `text` 字段。

## term：精确匹配

```java
client.search(s -> s
        .index("products_v1")
        .query(q -> q.term(t -> t
                .field("category")
                .value("book")
        )), ProductDoc.class);
```

`term` 适合 `keyword`、数值、布尔等精确字段。

> [!warning] 常见坑
> 不要对 `text` 字段直接用 `term` 查用户输入。`text` 入库时已经分词，原句可能不存在。

## range：范围查询

```java
client.search(s -> s
        .index("products_v1")
        .query(q -> q.range(r -> r
                .number(n -> n
                        .field("price")
                        .gte(50.0)
                        .lte(100.0)
                )
        )), ProductDoc.class);
```

## bool：组合查询

```java
client.search(s -> s
        .index("products_v1")
        .query(q -> q.bool(b -> b
                .must(m -> m.match(mm -> mm
                        .field("name")
                        .query("Java")
                ))
                .filter(f -> f.term(t -> t
                        .field("category")
                        .value("book")
                ))
                .filter(f -> f.range(r -> r
                        .number(n -> n.field("price").lte(100.0))
                ))
        )), ProductDoc.class);
```

## multi_match：多字段搜索

```java
client.search(s -> s
        .index("products_v1")
        .query(q -> q.multiMatch(m -> m
                .query("Java 搜索")
                .fields("name^3", "brand", "category")
        )), ProductDoc.class);
```

`name^3` 表示标题权重更高。

## query_string 为什么慎用

官方文档提醒：`query_string` 语法严格，用户输入非法语法会报错；不需要查询语法时更建议 `match`，需要查询语法时可考虑更宽容的 `simple_query_string`。

> [!danger] 搜索框别裸用 query_string
> 用户输入一个奇怪括号、冒号、通配符，就可能把搜索打挂或打慢。站内普通搜索框优先 `match` / `multi_match`。

## 搜索结果处理

```java
response.hits().hits().forEach(hit -> {
    ProductDoc product = hit.source();
    double score = hit.score() == null ? 0.0 : hit.score();
    System.out.println(score + " -> " + product.name());
});
```

## 本章小结

> [!success] DSL 心法
> 用户输入走 `match/multi_match`，业务条件走 `filter`，精确字段走 `term`，区间走 `range`，复杂组合交给 `bool`。

