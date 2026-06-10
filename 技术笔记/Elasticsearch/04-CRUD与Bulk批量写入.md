---
title: CRUD 与 Bulk 批量写入
tags:
  - Java
  - Elasticsearch
  - CRUD
  - Bulk
created: 2026-06-10
up: "[[00-MOC-Java-ES从0基础到大神]]"
description: 使用 Java API Client 完成文档新增、查询、更新、删除和批量写入。
---

# CRUD 与 Bulk 批量写入

> [!tip] 本章目标
> 你要能把业务对象写进 ES，也能把大量数据稳定地批量导入。

## 示例实体

```java
public record ProductDoc(
        String id,
        String name,
        String brand,
        String category,
        double price,
        int stock,
        String createdAt
) {}
```

## 新增或覆盖文档

```java
ProductDoc product = new ProductDoc(
        "p1001",
        "Java Elasticsearch 实战课",
        "Codex Academy",
        "book",
        99.0,
        100,
        "2026-06-10"
);

client.index(i -> i
        .index("products_v1")
        .id(product.id())
        .document(product)
);
```

> [!warning] index 不是 insert
> 指定同一个 `_id` 再次 `index`，通常会覆盖旧文档。想表达“只能新增，不许覆盖”，要用 create API 或设置 op type。

## 根据 ID 查询

```java
var response = client.get(g -> g
        .index("products_v1")
        .id("p1001"), ProductDoc.class);

if (response.found()) {
    ProductDoc doc = response.source();
    System.out.println(doc.name());
}
```

## 局部更新

```java
Map<String, Object> partial = Map.of(
        "price", 89.0,
        "stock", 88
);

client.update(u -> u
        .index("products_v1")
        .id("p1001")
        .doc(partial), ProductDoc.class);
```

## 删除文档

```java
client.delete(d -> d
        .index("products_v1")
        .id("p1001"));
```

## Bulk 批量写入

官方 Java Client 文档说明，Bulk 可以在一个请求里发送多个 index、create、delete、update 操作，比逐条请求更高效。

```java
List<ProductDoc> products = List.of(
        new ProductDoc("p1", "Java 入门", "A", "book", 39.0, 10, "2026-06-10"),
        new ProductDoc("p2", "ES 实战", "A", "book", 69.0, 20, "2026-06-10")
);

var bulkResponse = client.bulk(b -> {
    for (ProductDoc p : products) {
        b.operations(op -> op.index(idx -> idx
                .index("products_v1")
                .id(p.id())
                .document(p)
        ));
    }
    return b;
});

if (bulkResponse.errors()) {
    bulkResponse.items().forEach(item -> {
        if (item.error() != null) {
            System.err.println(item.id() + " -> " + item.error().reason());
        }
    });
}
```

> [!danger] Bulk 不是越大越好
> Bulk 太小，请求开销大；Bulk 太大，内存、网络、队列压力大。生产里要按文档大小、集群能力、失败率压测，不要拍脑袋一次塞几十万条。

## 写入链路的常见架构

```mermaid
graph LR
    A["业务写 MySQL"] --> B["发布领域事件或 binlog"]
    B --> C["MQ / 同步任务"]
    C --> D["构造 ProductDoc"]
    D --> E["Bulk 写 ES"]
    E --> F["搜索接口读取 ES"]
```

> [!success] 推荐做法
> MySQL 是事实来源，ES 是搜索读模型。同步失败时可以靠消息重试、补偿任务、全量重建恢复，而不是让业务主流程卡死在 ES 写入上。

## 本章练习

1. 写一个 `ProductDoc`。
2. 单条写入 1 条商品。
3. 根据 ID 查询它。
4. 用 Bulk 写入 100 条模拟商品。
5. 故意写错一个字段，观察 Bulk 局部失败。

