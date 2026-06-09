---
title: MongoDB 01 基础概念与适用场景
tags:
  - MongoDB
  - 数据库
  - NoSQL
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 01 基础概念与适用场景

## 一句话理解

MongoDB 是文档型数据库。它不是按“行 + 列”的二维表来存数据，而是把一条业务数据存成类似 JSON 的 BSON 文档。

典型文档：

```javascript
{
  _id: ObjectId("665000000000000000000001"),
  username: "zhangsan",
  age: 22,
  status: "ACTIVE",
  roles: ["USER", "ADMIN"],
  profile: {
    city: "Shanghai",
    phone: "13800000000"
  },
  createdAt: ISODate("2026-05-04T10:00:00Z")
}
```

## 核心概念

| MongoDB | 类比 MySQL | 说明 |
| --- | --- | --- |
| database | database | 数据库 |
| collection | table | 集合，一类文档的容器 |
| document | row | 一条 BSON 文档 |
| field | column | 文档字段 |
| `_id` | primary key | 文档主键，默认 ObjectId |
| index | index | 索引 |
| aggregation | group by / pipeline | 聚合管道 |
| replica set | 主从/高可用 | 副本集 |
| sharding | 分库分表 | 分片 |

## MongoDB 和 MySQL 的核心区别

| 对比项 | MongoDB | MySQL |
| --- | --- | --- |
| 数据模型 | 文档模型 | 关系模型 |
| 数据结构 | BSON/JSON 风格 | 表、行、列 |
| Schema | 灵活 | 严格 |
| Join | 支持 `$lookup`，但不是主场 | 强项 |
| 事务 | 支持，单文档天然原子 | 强项 |
| 扩展 | 天然支持分片 | 通常要分库分表 |
| 适合场景 | 文档聚合、灵活字段、高吞吐 | 交易、强关系、强一致 |

## 适合用 MongoDB 的场景

### 用户画像

用户画像字段多、变化快，不同用户可能有不同标签、偏好、设备信息。

```javascript
{
  userId: "u1",
  base: {
    city: "Shanghai",
    gender: "MALE"
  },
  tags: ["high_value", "new_user"],
  preferences: {
    categories: ["book", "digital"],
    priceRange: "100-500"
  }
}
```

### 内容系统

文章、评论摘要、标签、作者快照天然像一个文档。

```javascript
{
  title: "MongoDB 入门",
  author: {
    id: "u1",
    name: "zhangsan"
  },
  tags: ["database", "mongodb"],
  stats: {
    viewCount: 100,
    likeCount: 10
  }
}
```

### 商品扩展属性

不同品类商品字段不同，如果用 MySQL 表结构会很碎。

```javascript
{
  sku: "A001",
  category: "keyboard",
  attrs: {
    layout: "87 keys",
    switchType: "red",
    wireless: true
  }
}
```

### 日志和事件

日志字段经常变化，payload 可以很灵活。

```javascript
{
  eventId: "e1001",
  type: "LOGIN",
  userId: "u1",
  payload: {
    ip: "127.0.0.1",
    device: "Windows"
  },
  occurredAt: ISODate("2026-05-04T10:00:00Z")
}
```

## 不适合优先用 MongoDB 的场景

- 核心账务、余额、交易流水。
- 查询强依赖复杂多表 Join。
- 数据模型高度规范化，关系比文档更重要。
- 需要严格外键约束。
- 团队把 MongoDB 当作“随便存 JSON”的临时仓库。

## 关键心法

MongoDB 建模时先问：

1. 这个业务的聚合根是什么？
2. 一次页面或接口通常要读哪些数据？
3. 哪些字段总是一起读、一起写？
4. 哪些字段会无限增长？
5. 哪些字段需要独立查询？
6. 哪些查询必须有索引？

如果一类数据经常一起读、数量可控、生命周期一致，优先嵌入。  
如果数据独立存在、数量无限增长、被多处共享，优先引用。

## 下一步

先把本地环境跑起来：[[MongoDB 02 本地环境与 mongosh]]

