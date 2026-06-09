---
title: MongoDB 07 Java 与 Spring Boot 集成
tags:
  - MongoDB
  - Java
  - SpringBoot
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 07 Java 与 Spring Boot 集成

## Java 原生驱动

Maven 依赖：

```xml
<dependency>
  <groupId>org.mongodb</groupId>
  <artifactId>mongodb-driver-sync</artifactId>
</dependency>
```

如果使用 Spring Boot，优先让 Spring Boot 管理版本，不要随便手写旧版本。

## Java 建立连接

```java
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

public class MongoDemo {
    public static void main(String[] args) {
        String uri = "mongodb://root:123456@localhost:27017/appdb?authSource=admin";

        try (MongoClient client = MongoClients.create(uri)) {
            MongoDatabase database = client.getDatabase("appdb");
            MongoCollection<Document> users = database.getCollection("users");

            Document user = new Document("username", "zhangsan")
                    .append("age", 22)
                    .append("status", "ACTIVE");

            users.insertOne(user);

            Document found = users.find(new Document("username", "zhangsan")).first();
            System.out.println(found);
        }
    }
}
```

要点：

- `MongoClient` 应该复用。
- 不要每次请求创建一个 `MongoClient`。
- 连接池、超时、认证都放在连接字符串或配置中。

## Java CRUD

```java
import static com.mongodb.client.model.Filters.*;
import static com.mongodb.client.model.Updates.*;
import static com.mongodb.client.model.Sorts.*;
import static com.mongodb.client.model.Projections.*;
```

```java
// 插入
users.insertOne(new Document("username", "lisi")
        .append("age", 25)
        .append("status", "ACTIVE"));

// 查询一条
Document user = users.find(eq("username", "lisi")).first();

// 查询列表
users.find(and(eq("status", "ACTIVE"), gte("age", 18)))
        .projection(fields(include("username", "age"), excludeId()))
        .sort(descending("age"))
        .limit(20)
        .forEach(doc -> System.out.println(doc.toJson()));

// 更新
users.updateOne(
        eq("username", "lisi"),
        combine(set("age", 26), currentDate("updatedAt"))
);

// 删除
users.deleteOne(eq("username", "lisi"));
```

## Spring Boot 依赖

```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

## application.yml

无认证：

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/appdb
```

有认证：

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://root:123456@localhost:27017/appdb?authSource=admin
```

## 实体类

```java
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;

@Document("users")
public class UserDocument {

    @Id
    private String id;

    @Indexed(unique = true)
    private String username;

    private Integer age;
    private String status;
    private List<String> roles;
    private Profile profile;
    private Instant createdAt;
    private Instant updatedAt;

    public static class Profile {
        private String city;
        private String phone;
    }
}
```

说明：

- `@Document("users")` 映射集合。
- `@Id` 映射 `_id`。
- `@Indexed` 声明索引，但生产是否自动建索引要谨慎。

## MongoRepository

```java
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends MongoRepository<UserDocument, String> {

    Optional<UserDocument> findByUsername(String username);

    List<UserDocument> findByStatus(String status);

    List<UserDocument> findByStatusAndAgeGreaterThanEqual(String status, Integer age);
}
```

适合：

- 简单 CRUD。
- 方法名派生查询。
- 分页排序。

## @Query

```java
import org.springframework.data.mongodb.repository.Query;

public interface UserRepository extends MongoRepository<UserDocument, String> {

    @Query("{ 'status': ?0, 'age': { $gte: ?1 } }")
    List<UserDocument> findActiveAdults(String status, Integer minAge);
}
```

适合方法名太长，或者需要 MongoDB 原生查询条件。

## MongoTemplate

`MongoTemplate` 适合复杂查询、动态条件、局部更新、聚合。

```java
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public class UserMongoDao {

    private final MongoTemplate mongoTemplate;

    public UserMongoDao(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public List<UserDocument> search(String status, Integer minAge, String city) {
        Criteria criteria = Criteria.where("status").is(status);

        if (minAge != null) {
            criteria = criteria.and("age").gte(minAge);
        }

        if (city != null && !city.isBlank()) {
            criteria = criteria.and("profile.city").is(city);
        }

        Query query = Query.query(criteria)
                .with(Sort.by(Sort.Direction.DESC, "createdAt"))
                .limit(20);

        query.fields().include("username").include("age").include("profile.city");

        return mongoTemplate.find(query, UserDocument.class);
    }

    public void updateLastActive(String username) {
        Query query = Query.query(Criteria.where("username").is(username));
        Update update = new Update()
                .set("lastActiveAt", Instant.now())
                .currentDate("updatedAt");

        mongoTemplate.updateFirst(query, update, UserDocument.class);
    }
}
```

## Repository vs MongoTemplate

| 方式 | 优点 | 适合 |
| --- | --- | --- |
| MongoRepository | 简单、声明式、代码少 | 标准 CRUD |
| `@Query` | 可以写原生条件 | 中等复杂查询 |
| MongoTemplate | 灵活、可动态拼条件 | 复杂查询、聚合、局部更新 |

## 常见建议

- 简单业务先用 Repository。
- 查询条件复杂时换 MongoTemplate。
- 不要把所有字段都查出来，能 projection 就 projection。
- 连接池和超时必须配置。
- id 类型要统一，避免 ObjectId 和 String 混用。

## 下一步

学会代码后，要会设计文档结构：[[MongoDB 08 文档建模设计]]

