---
title: 06-数据访问 R2DBC 与 ReactiveRepository
tags:
  - Java
  - WebFlux
  - R2DBC
  - ReactiveRepository
created: 2026-06-09
up: "[[00-MOC-WebFlux总览]]"
description: 掌握 WebFlux 中的响应式数据访问，理解为什么 JDBC/JPA 是阻塞模型，学习 R2DBC、ReactiveCrudRepository、事务和数据建模注意点。
---

# 06-数据访问 R2DBC 与 ReactiveRepository

> [!info] 本章抓什么
> WebFlux 的数据库访问要特别谨慎。真正响应式依赖底层驱动支持非阻塞，R2DBC 是 SQL 世界的常见选择，但它不是 JPA 的响应式复制品。

## 1. 为什么不能直接把 JPA 当响应式

JDBC 和 JPA 的调用模型本质是阻塞的。即使你把 JPA 调用包装成 `Mono.fromCallable()`，数据库线程还是会阻塞，只是被挪到另一个线程池里。

```java
Mono.fromCallable(() -> jpaRepository.findById(id))
        .subscribeOn(Schedulers.boundedElastic());
```

这种写法可以作为迁移期兜底，但不等于真正响应式数据访问。真正响应式数据库访问需要底层驱动支持非阻塞协议，例如 R2DBC、Reactive MongoDB。

> [!warning] 迁移期提醒
> `Mono.fromCallable(...).subscribeOn(boundedElastic)` 是“隔离阻塞”的办法，不是“把阻塞变非阻塞”的魔法。它能保护事件循环线程，但仍然会消耗额外线程和数据库连接。

## 2. R2DBC 依赖示例

PostgreSQL：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-r2dbc</artifactId>
</dependency>

<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>r2dbc-postgresql</artifactId>
    <scope>runtime</scope>
</dependency>
```

配置：

```yaml
spring:
  r2dbc:
    url: r2dbc:postgresql://localhost:5432/demo
    username: demo
    password: demo
```

## 3. 实体对象

```java
@Table("users")
public class UserEntity {
    @Id
    private Long id;
    private String name;
    private String email;
    private LocalDateTime createdAt;

    // getter/setter
}
```

R2DBC 不是 JPA，不要期待 `@OneToMany`、懒加载、一级缓存、脏检查这些 ORM 能力。它更接近响应式 SQL Mapper。

## 4. ReactiveCrudRepository

```java
public interface UserRepository extends ReactiveCrudRepository<UserEntity, Long> {
    Mono<UserEntity> findByEmail(String email);

    Flux<UserEntity> findByNameContaining(String keyword);
}
```

Service：

```java
@Service
public class UserService {
    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public Mono<UserEntity> create(CreateUserRequest request) {
        UserEntity entity = new UserEntity();
        entity.setName(request.name());
        entity.setEmail(request.email());
        entity.setCreatedAt(LocalDateTime.now());
        return userRepository.save(entity);
    }

    public Mono<UserEntity> get(Long id) {
        return userRepository.findById(id)
                .switchIfEmpty(Mono.error(new NotFoundException("用户不存在")));
    }
}
```

> [!success] 建模建议
> R2DBC 更适合显式 SQL、轻量映射和读写模型清晰的系统。复杂对象图、懒加载、级联保存这些 JPA 习惯，需要重新设计。

## 5. DatabaseClient

复杂 SQL 可用 `DatabaseClient`：

```java
@Repository
public class UserQueryRepository {
    private final DatabaseClient databaseClient;

    public UserQueryRepository(DatabaseClient databaseClient) {
        this.databaseClient = databaseClient;
    }

    public Flux<UserSummary> search(String keyword) {
        return databaseClient.sql("""
                select id, name, email
                from users
                where name like :keyword
                order by id desc
                limit 50
                """)
                .bind("keyword", "%" + keyword + "%")
                .map((row, meta) -> new UserSummary(
                        row.get("id", Long.class),
                        row.get("name", String.class),
                        row.get("email", String.class)))
                .all();
    }
}
```

## 6. 响应式事务

```java
@Service
public class OrderService {
    private final TransactionalOperator tx;
    private final OrderRepository orderRepository;
    private final StockRepository stockRepository;

    public OrderService(ReactiveTransactionManager txManager,
                        OrderRepository orderRepository,
                        StockRepository stockRepository) {
        this.tx = TransactionalOperator.create(txManager);
        this.orderRepository = orderRepository;
        this.stockRepository = stockRepository;
    }

    public Mono<Order> createOrder(CreateOrderCommand command) {
        return stockRepository.deduct(command.skuId(), command.quantity())
                .then(orderRepository.save(Order.from(command)))
                .as(tx::transactional);
    }
}
```

响应式事务必须让整个链路保持在一个 Publisher 里。中途 `subscribe()` 或 `block()` 都可能破坏事务边界。

## 7. 多表关联怎么处理

R2DBC 没有 JPA 那种自动对象图加载，常见做法：

1. 小规模关联：查主表后 `flatMap` 查子表，再组装 DTO。
2. 查询视图：用 SQL join 直接返回读模型。
3. CQRS：写模型保持规范化，读模型为查询优化。
4. 高频聚合：用缓存、搜索引擎或预计算表。

示例：

```java
public Mono<UserDetail> getDetail(Long userId) {
    Mono<UserEntity> user = userRepository.findById(userId);
    Flux<OrderEntity> orders = orderRepository.findRecentByUserId(userId);

    return user.zipWith(orders.collectList())
            .map(tuple -> new UserDetail(tuple.getT1(), tuple.getT2()));
}
```

## 8. 数据访问避坑

1. 不要把 JPA Repository 直接放进 WebFlux 主链路。
2. 不要在响应式事务内部手动 `subscribe()`。
3. 不要为了方便把大结果集 `collectList()`。
4. 不要忽略连接池，数据库连接同样是稀缺资源。
5. 不要以为 R2DBC 是完整 ORM，它更轻量，也更要求你理解 SQL。
6. 查询必须有超时、分页和索引设计。

> [!danger] 数据层红线
> 没有分页的大查询、没有上限的 `collectList()`、事务链路中手动 `subscribe()`，都是 WebFlux 数据层的高危写法。
