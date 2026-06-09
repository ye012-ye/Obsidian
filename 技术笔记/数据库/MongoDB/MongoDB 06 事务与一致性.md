---
title: MongoDB 06 事务与一致性
tags:
  - MongoDB
  - 事务
  - 一致性
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 06 事务与一致性

## 先记住一句话

MongoDB 单文档写入天然原子。能放进一个文档里完成的一次业务修改，不需要多文档事务。

例如：

```javascript
db.users.updateOne(
  { username: "zhangsan" },
  {
    $set: { status: "ACTIVE" },
    $inc: { loginCount: 1 },
    $currentDate: { updatedAt: true }
  }
)
```

这次更新中，同一个文档里的多个字段要么一起成功，要么失败。

## 什么时候需要事务

需要多文档事务的场景：

- 同一次业务写多个集合。
- 同一次业务写多条文档。
- 必须 commit/rollback。
- 订单创建同时写订单、扣库存、写流水。

不建议滥用事务：

- 能用嵌入文档解决，不要拆集合再用事务。
- 不要在事务里做远程 HTTP。
- 不要在事务里做长时间计算。
- 高频大事务会影响性能。

## mongosh 事务示例

事务通常需要副本集环境。

```javascript
const session = db.getMongo().startSession()
const appdb = session.getDatabase("appdb")

session.startTransaction()

try {
  appdb.orders.insertOne({
    orderNo: "O1002",
    userId: "u1",
    amount: 200,
    createdAt: new Date()
  })

  appdb.users.updateOne(
    { username: "zhangsan" },
    { $inc: { orderCount: 1 } }
  )

  session.commitTransaction()
} catch (e) {
  session.abortTransaction()
  throw e
} finally {
  session.endSession()
}
```

## Java 事务示例

```java
try (ClientSession session = client.startSession()) {
    session.startTransaction();
    try {
        orders.insertOne(session, new Document("orderNo", "O1001")
                .append("userId", "u1")
                .append("amount", 100));

        users.updateOne(session,
                new Document("userId", "u1"),
                new Document("$inc", new Document("orderCount", 1)));

        session.commitTransaction();
    } catch (RuntimeException e) {
        session.abortTransaction();
        throw e;
    }
}
```

要点：

- 事务需要 `ClientSession`。
- 事务内每个操作都要传同一个 session。
- 生产代码要处理重试。

## Spring Boot 事务

配置事务管理器：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.MongoTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@EnableTransactionManagement
public class MongoConfig {

    @Bean
    MongoTransactionManager transactionManager(MongoDatabaseFactory factory) {
        return new MongoTransactionManager(factory);
    }
}
```

业务方法：

```java
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    private final MongoTemplate mongoTemplate;

    public OrderService(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Transactional
    public void createOrder(OrderDocument order) {
        mongoTemplate.insert(order);

        Query query = Query.query(Criteria.where("userId").is(order.getUserId()));
        Update update = new Update().inc("orderCount", 1);

        mongoTemplate.updateFirst(query, update, UserDocument.class);
    }
}
```

注意：

- 没有 `MongoTransactionManager`，`@Transactional` 对 MongoDB 不会按你预期工作。
- 本地测试事务建议用副本集。
- 不要用事务掩盖错误的文档边界。

## 一致性设计建议

### 优先单文档

订单详情可以把商品快照放在订单文档里：

```javascript
{
  orderNo: "O1001",
  userId: "u1",
  items: [
    { sku: "A001", name: "Keyboard", price: 199, count: 1 }
  ],
  amount: 199
}
```

创建订单时只写一条订单文档，不需要 Join 商品表才能展示历史订单。

### 允许合理冗余

冗余不是坏事。MongoDB 里为了读性能和历史快照，常冗余：

- 用户昵称快照。
- 商品名称快照。
- 下单时价格。
- 统计计数。

### 需要最终一致时用事件

比如创建订单后更新用户订单数，可以：

1. 写订单。
2. 发事件。
3. 异步消费更新用户统计。
4. 失败可重试。

这样比把所有事情塞进一个大事务更稳。

## 下一步

Java 和 Spring Boot 代码看：[[MongoDB 07 Java 与 Spring Boot 集成]]

