---
title: MongoDB 05 聚合管道
tags:
  - MongoDB
  - 聚合
  - aggregation
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 05 聚合管道

## 聚合管道是什么

aggregation pipeline 把数据处理拆成多个 stage，前一个 stage 的输出是下一个 stage 的输入。

常见 stage：

| stage | 作用 |
| --- | --- |
| `$match` | 过滤文档 |
| `$project` | 选择、重命名、计算字段 |
| `$group` | 分组统计 |
| `$sort` | 排序 |
| `$limit` | 限制数量 |
| `$skip` | 跳过数量 |
| `$unwind` | 展开数组 |
| `$lookup` | 类 Join |
| `$addFields` | 增加字段 |

## 基本分组统计

按状态统计用户数：

```javascript
db.users.aggregate([
  {
    $group: {
      _id: "$status",
      count: { $sum: 1 }
    }
  },
  {
    $sort: { count: -1 }
  }
])
```

## 先过滤再分组

```javascript
db.users.aggregate([
  {
    $match: {
      createdAt: {
        $gte: ISODate("2026-01-01T00:00:00Z")
      }
    }
  },
  {
    $group: {
      _id: "$profile.city",
      count: { $sum: 1 },
      avgAge: { $avg: "$age" }
    }
  },
  {
    $sort: { count: -1 }
  }
])
```

优化原则：

- `$match` 尽量放前面。
- `$match` 字段尽量有索引。
- 先减少数据量，再做 `$group`、`$sort`。

## project 字段投影

```javascript
db.users.aggregate([
  {
    $project: {
      _id: 0,
      username: 1,
      city: "$profile.city",
      isAdult: { $gte: ["$age", 18] }
    }
  }
])
```

作用：

- 控制返回字段。
- 重命名字段。
- 计算派生字段。

## unwind 展开数组

订单数据：

```javascript
db.orders.insertOne({
  orderNo: "O1001",
  items: [
    { sku: "A001", count: 2, price: 100 },
    { sku: "B001", count: 1, price: 50 }
  ]
})
```

按商品统计销售数量和金额：

```javascript
db.orders.aggregate([
  { $unwind: "$items" },
  {
    $group: {
      _id: "$items.sku",
      totalCount: { $sum: "$items.count" },
      totalAmount: {
        $sum: {
          $multiply: ["$items.count", "$items.price"]
        }
      }
    }
  },
  { $sort: { totalAmount: -1 } }
])
```

## lookup 关联查询

订单：

```javascript
db.orders.insertOne({
  orderNo: "O1001",
  userId: ObjectId("665000000000000000000001"),
  amount: 150
})
```

用户：

```javascript
db.users.insertOne({
  _id: ObjectId("665000000000000000000001"),
  username: "zhangsan"
})
```

关联：

```javascript
db.orders.aggregate([
  {
    $lookup: {
      from: "users",
      localField: "userId",
      foreignField: "_id",
      as: "user"
    }
  },
  { $unwind: "$user" },
  {
    $project: {
      orderNo: 1,
      amount: 1,
      username: "$user.username"
    }
  }
])
```

注意：

- MongoDB 支持 `$lookup`，但不要把它当 MySQL Join 随便用。
- 高频查询依赖 `$lookup` 时，应重新考虑建模。
- 可以在订单里冗余用户昵称、商品名称、价格快照。

## 聚合分页

```javascript
db.orders.aggregate([
  { $match: { status: "PAID" } },
  { $sort: { createdAt: -1 } },
  { $skip: 0 },
  { $limit: 20 },
  {
    $project: {
      orderNo: 1,
      amount: 1,
      createdAt: 1
    }
  }
])
```

如果数据大，避免深分页，优先用游标条件 + `$limit`。

## 大聚合注意事项

- 聚合不是越复杂越好，复杂报表可以离线计算。
- `$match`、`$sort` 尽量利用索引。
- `$group` 会消耗内存。
- 大数据量聚合可考虑 `allowDiskUse`。
- 高频统计可以预聚合，保存统计结果。

## 下一步

涉及多文档一致性时看：[[MongoDB 06 事务与一致性]]

