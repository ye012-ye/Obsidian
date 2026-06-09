---
title: MongoDB 08 文档建模设计
tags:
  - MongoDB
  - 建模
  - 文档设计
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 08 文档建模设计

## 建模核心

MongoDB 不是先想“表怎么拆”，而是先想“业务怎么读写”。

关键问题：

1. 哪些数据总是一起读取？
2. 哪些数据总是一起更新？
3. 哪些数据生命周期一致？
4. 哪些数组可能无限增长？
5. 哪些字段要独立查询？
6. 哪些字段要排序分页？

## 嵌入式文档

```javascript
{
  orderNo: "O1001",
  userId: "u1",
  items: [
    { sku: "A001", name: "Keyboard", count: 1, price: 199 },
    { sku: "B001", name: "Mouse", count: 1, price: 99 }
  ],
  amount: 298
}
```

适合：

- 子数据总是跟父数据一起读。
- 子数据生命周期依赖父数据。
- 子数据数量可控。
- 不需要频繁单独查询子数据。

优点：

- 一次查询拿到完整数据。
- 减少 Join。
- 单文档更新天然原子。

风险：

- 数组无限增长会导致文档膨胀。
- 子数据被多处共享时会产生冗余更新。

## 引用

```javascript
{
  orderNo: "O1001",
  userId: ObjectId("665000000000000000000001"),
  amount: 298
}
```

适合：

- 被引用对象独立存在。
- 被多个聚合根共享。
- 数据数量巨大。
- 需要独立查询和更新。

缺点：

- 查询时可能需要二次查询或 `$lookup`。
- 业务代码要处理一致性。

## 订单建模

推荐订单保存快照：

```javascript
{
  orderNo: "O1001",
  userId: "u1",
  userSnapshot: {
    username: "zhangsan",
    phone: "13800000000"
  },
  items: [
    {
      sku: "A001",
      name: "Keyboard",
      price: 199,
      count: 1
    }
  ],
  amount: 199,
  status: "PAID",
  createdAt: ISODate("2026-05-04T10:00:00Z")
}
```

为什么：

- 历史订单要保留下单时价格和名称。
- 查询订单详情不需要 Join 商品表。
- 订单是天然聚合根。

常用索引：

```javascript
db.orders.createIndex({ userId: 1, createdAt: -1 })
db.orders.createIndex({ orderNo: 1 }, { unique: true })
db.orders.createIndex({ status: 1, createdAt: -1 })
```

## 用户画像建模

```javascript
{
  userId: "u1",
  base: {
    city: "Shanghai",
    gender: "MALE",
    birthday: "2000-01-01"
  },
  tags: ["high_value", "new_user"],
  preferences: {
    categories: ["book", "digital"],
    priceRange: "100-500"
  },
  updatedAt: ISODate("2026-05-04T10:00:00Z")
}
```

适合 MongoDB 的原因：

- 字段灵活。
- 查询通常按用户维度整体读取。
- 标签和偏好可以逐步扩展。

索引：

```javascript
db.user_profiles.createIndex({ userId: 1 }, { unique: true })
db.user_profiles.createIndex({ tags: 1 })
db.user_profiles.createIndex({ "base.city": 1 })
```

## 日志事件建模

```javascript
{
  eventId: "e1001",
  type: "LOGIN",
  userId: "u1",
  ip: "127.0.0.1",
  payload: {
    device: "Windows",
    source: "web"
  },
  occurredAt: ISODate("2026-05-04T10:00:00Z")
}
```

索引：

```javascript
db.events.createIndex({ userId: 1, occurredAt: -1 })
db.events.createIndex({ type: 1, occurredAt: -1 })
db.events.createIndex({ occurredAt: 1 }, { expireAfterSeconds: 90 * 24 * 3600 })
```

日志通常单独 collection，不要无限塞进用户文档数组。

## 冗余字段不是错误

MongoDB 里常见合理冗余：

- 订单里冗余商品名称、价格快照。
- 评论里冗余用户昵称。
- 内容里冗余统计计数。
- 消息里冗余发送人展示信息。

冗余的目标：

- 减少查询次数。
- 保留历史快照。
- 避免复杂 `$lookup`。

代价：

- 更新冗余字段时需要同步。
- 要接受部分场景的最终一致。

## 错误建模信号

- 每个对象都拆一个 collection。
- 高频接口需要多个 `$lookup`。
- 频繁跨集合事务。
- 文档数组无限增长。
- 查询字段没有索引。
- 为了迁就前端随便塞字段，没人维护 schema。

## 下一步

生产环境要会查问题：[[MongoDB 09 运维备份与性能排查]]

