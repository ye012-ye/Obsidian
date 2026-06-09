---
title: MongoDB 04 索引与执行计划
tags:
  - MongoDB
  - 索引
  - explain
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 04 索引与执行计划

## 为什么索引重要

没有索引时，MongoDB 需要扫描大量文档。数据少时没感觉，数据多后会出现 CPU 高、磁盘 IO 高、查询慢。

查看执行计划：

```javascript
db.users.find({ username: "zhangsan" }).explain("executionStats")
```

重点看：

| 字段 | 含义 |
| --- | --- |
| `COLLSCAN` | 集合扫描，通常说明没用上合适索引 |
| `IXSCAN` | 索引扫描 |
| `totalDocsExamined` | 扫描了多少文档 |
| `totalKeysExamined` | 扫描了多少索引键 |
| `executionTimeMillis` | 执行耗时 |

理想状态不是“有索引就行”，而是扫描的文档数量接近返回数量。

## 单字段索引

```javascript
db.users.createIndex({ username: 1 })
```

查看索引：

```javascript
db.users.getIndexes()
```

删除索引：

```javascript
db.users.dropIndex({ username: 1 })
```

## 唯一索引

```javascript
db.users.createIndex(
  { username: 1 },
  { unique: true }
)
```

适合：

- 用户名唯一。
- 手机号唯一。
- 外部系统 id 唯一。

注意：

- 创建前不能已有重复数据。
- 对可空字段建唯一索引要谨慎，常配合 partial index。

## 复合索引

常见查询：

```javascript
db.users.find({ status: "ACTIVE" })
  .sort({ createdAt: -1 })
  .limit(20)
```

索引：

```javascript
db.users.createIndex({
  status: 1,
  createdAt: -1
})
```

复合索引设计原则：

- 等值过滤字段放前面。
- 排序字段跟在等值字段后面。
- 范围字段会影响后续字段继续利用索引。
- 按真实查询模式建索引，不按“字段看起来重要”建索引。

## 最左前缀

索引：

```javascript
{ status: 1, age: -1, createdAt: -1 }
```

能较好利用：

```javascript
db.users.find({ status: "ACTIVE" })
db.users.find({ status: "ACTIVE", age: { $gte: 18 } })
```

不能直接高效利用：

```javascript
db.users.find({ age: { $gte: 18 } })
```

因为跳过了最左侧字段 `status`。

## 排序索引

查询：

```javascript
db.users.find({ status: "ACTIVE" })
  .sort({ age: -1, createdAt: -1 })
```

索引：

```javascript
db.users.createIndex({
  status: 1,
  age: -1,
  createdAt: -1
})
```

如果排序不能走索引，MongoDB 可能需要内存排序，数据量大时性能差。

## 游标式分页

不要深分页：

```javascript
db.users.find().sort({ createdAt: -1 }).skip(100000).limit(20)
```

推荐用游标：

第一页：

```javascript
db.users.find({ status: "ACTIVE" })
  .sort({ createdAt: -1, _id: -1 })
  .limit(20)
```

下一页：

```javascript
db.users.find({
  status: "ACTIVE",
  $or: [
    { createdAt: { $lt: ISODate("2026-05-04T10:00:00Z") } },
    {
      createdAt: ISODate("2026-05-04T10:00:00Z"),
      _id: { $lt: ObjectId("665000000000000000000001") }
    }
  ]
})
.sort({ createdAt: -1, _id: -1 })
.limit(20)
```

索引：

```javascript
db.users.createIndex({ status: 1, createdAt: -1, _id: -1 })
```

## TTL 索引

自动过期删除：

```javascript
db.sessions.createIndex(
  { expireAt: 1 },
  { expireAfterSeconds: 0 }
)
```

插入：

```javascript
db.sessions.insertOne({
  token: "abc",
  userId: "u1",
  expireAt: new Date(Date.now() + 30 * 60 * 1000)
})
```

适合：

- 登录会话。
- 验证码。
- 临时任务。
- 临时缓存数据。

注意：TTL 删除不是实时毫秒级，有后台扫描延迟。

## partial index

只给符合条件的文档建索引：

```javascript
db.users.createIndex(
  { email: 1 },
  {
    unique: true,
    partialFilterExpression: {
      email: { $exists: true }
    }
  }
)
```

适合：

- 字段不是每条文档都有。
- 只索引未删除数据。
- 降低索引大小。

## 文本索引

```javascript
db.articles.createIndex({
  title: "text",
  content: "text"
})
```

查询：

```javascript
db.articles.find({
  $text: { $search: "mongodb 索引" }
})
```

中文搜索、相关性排序、搜索高亮等复杂能力，通常考虑 Elasticsearch、OpenSearch 或 Atlas Search。

## 索引不是越多越好

索引代价：

- 占磁盘。
- 占内存。
- 写入、更新、删除都要维护索引。
- 太多相似索引会增加维护成本。

上线前建议：

1. 列出核心查询。
2. 给核心查询设计复合索引。
3. 用 `explain("executionStats")` 验证。
4. 删除重复或长期不用的索引。

## 下一步

统计和报表看聚合：[[MongoDB 05 聚合管道]]

