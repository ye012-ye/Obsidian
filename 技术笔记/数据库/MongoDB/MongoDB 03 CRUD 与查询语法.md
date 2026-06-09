---
title: MongoDB 03 CRUD 与查询语法
tags:
  - MongoDB
  - CRUD
  - 查询
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 03 CRUD 与查询语法

## 准备数据

```javascript
use appdb
```

```javascript
db.users.insertMany([
  {
    username: "zhangsan",
    age: 22,
    status: "ACTIVE",
    roles: ["USER"],
    profile: { city: "Shanghai", phone: "13800000000" },
    createdAt: new Date()
  },
  {
    username: "lisi",
    age: 25,
    status: "ACTIVE",
    roles: ["USER", "ADMIN"],
    profile: { city: "Hangzhou" },
    createdAt: new Date()
  },
  {
    username: "wangwu",
    age: 30,
    status: "DISABLED",
    roles: ["USER"],
    profile: { city: "Beijing" },
    createdAt: new Date()
  }
])
```

## 插入

插入一条：

```javascript
db.users.insertOne({
  username: "zhaoliu",
  age: 28,
  status: "ACTIVE",
  roles: ["USER"],
  createdAt: new Date()
})
```

插入多条：

```javascript
db.users.insertMany([
  { username: "a", age: 18 },
  { username: "b", age: 19 }
])
```

## 查询

查询全部：

```javascript
db.users.find()
```

格式化：

```javascript
db.users.find().pretty()
```

查询一条：

```javascript
db.users.findOne({ username: "zhangsan" })
```

只返回部分字段：

```javascript
db.users.find(
  { status: "ACTIVE" },
  { username: 1, age: 1, _id: 0 }
)
```

## 比较查询

```javascript
db.users.find({ age: { $gt: 18 } })
db.users.find({ age: { $gte: 18 } })
db.users.find({ age: { $lt: 30 } })
db.users.find({ age: { $lte: 30 } })
db.users.find({ age: { $ne: 25 } })
```

范围：

```javascript
db.users.find({
  age: { $gte: 18, $lte: 30 }
})
```

## in / nin

```javascript
db.users.find({
  status: { $in: ["ACTIVE", "PENDING"] }
})
```

```javascript
db.users.find({
  status: { $nin: ["DISABLED", "DELETED"] }
})
```

## and / or

多个字段默认是 and：

```javascript
db.users.find({
  status: "ACTIVE",
  age: { $gte: 18 }
})
```

or：

```javascript
db.users.find({
  $or: [
    { username: "zhangsan" },
    { age: { $gte: 30 } }
  ]
})
```

组合：

```javascript
db.users.find({
  status: "ACTIVE",
  $or: [
    { age: { $lt: 20 } },
    { roles: "ADMIN" }
  ]
})
```

## 嵌套字段

```javascript
db.users.find({
  "profile.city": "Shanghai"
})
```

更新嵌套字段：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $set: { "profile.city": "Hangzhou" } }
)
```

## 数组查询

数组包含某个值：

```javascript
db.users.find({ roles: "ADMIN" })
```

数组同时包含多个值：

```javascript
db.users.find({
  roles: { $all: ["USER", "ADMIN"] }
})
```

数组长度：

```javascript
db.users.find({
  roles: { $size: 2 }
})
```

数组对象用 `$elemMatch`：

```javascript
db.orders.insertOne({
  orderNo: "O1001",
  items: [
    { sku: "A001", count: 2, price: 100 },
    { sku: "B001", count: 1, price: 50 }
  ]
})
```

```javascript
db.orders.find({
  items: {
    $elemMatch: {
      sku: "A001",
      count: { $gte: 2 }
    }
  }
})
```

## 字段是否存在

```javascript
db.users.find({
  deletedAt: { $exists: false }
})
```

## 正则查询

```javascript
db.users.find({
  username: /^zhang/
})
```

注意：

- `/^abc/` 前缀查询有机会用索引。
- `/abc/` 包含查询通常难以高效使用普通索引。
- 大量文本搜索不要只靠正则，应考虑 text index 或搜索引擎。

## 更新

`$set` 设置字段：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $set: { age: 23, updatedAt: new Date() } }
)
```

`$unset` 删除字段：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $unset: { "profile.phone": "" } }
)
```

`$inc` 自增：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $inc: { loginCount: 1 } }
)
```

`$push` 数组追加：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $push: { roles: "AUDITOR" } }
)
```

`$addToSet` 去重追加：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $addToSet: { roles: "ADMIN" } }
)
```

`$pull` 移除数组元素：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  { $pull: { roles: "AUDITOR" } }
)
```

## upsert

不存在就插入：

```javascript
db.users.updateOne(
  { username: "zhaoliu" },
  {
    $set: {
      age: 28,
      status: "ACTIVE",
      updatedAt: new Date()
    },
    $setOnInsert: {
      createdAt: new Date()
    }
  },
  { upsert: true }
)
```

适合幂等同步外部数据。

## 替换文档

```javascript
db.users.replaceOne(
  { username: "zhangsan" },
  {
    username: "zhangsan",
    age: 24,
    status: "ACTIVE",
    roles: ["USER", "ADMIN"],
    updatedAt: new Date()
  }
)
```

注意：`replaceOne` 会替换整条文档，除了 `_id`。只改几个字段时用 `$set`。

## 删除

删除一条：

```javascript
db.users.deleteOne({ username: "wangwu" })
```

删除多条：

```javascript
db.users.deleteMany({ status: "DISABLED" })
```

清空集合：

```javascript
db.users.deleteMany({})
```

生产环境删除前先用同样条件 `find()` 确认。

## 排序分页

排序：

```javascript
db.users.find({ status: "ACTIVE" }).sort({ age: -1 })
```

普通分页：

```javascript
db.users.find({ status: "ACTIVE" })
  .sort({ createdAt: -1 })
  .skip(0)
  .limit(20)
```

深分页不要大量使用 `skip`，数据越多越慢。深分页看 [[MongoDB 04 索引与执行计划]]。

## 下一步

CRUD 会了以后，必须学索引：[[MongoDB 04 索引与执行计划]]

