---
title: MongoDB 09 运维备份与性能排查
tags:
  - MongoDB
  - 运维
  - 备份
  - 性能排查
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 09 运维备份与性能排查

## 备份恢复

### 导出 JSON

```bash
mongoexport \
  --uri="mongodb://root:123456@localhost:27017/appdb?authSource=admin" \
  --collection=users \
  --out=users.json
```

### 导入 JSON

```bash
mongoimport \
  --uri="mongodb://root:123456@localhost:27017/appdb?authSource=admin" \
  --collection=users \
  --file=users.json
```

### 备份数据库

```bash
mongodump \
  --uri="mongodb://root:123456@localhost:27017/appdb?authSource=admin" \
  --out=backup
```

### 恢复数据库

```bash
mongorestore \
  --uri="mongodb://root:123456@localhost:27017/appdb?authSource=admin" \
  backup
```

区别：

- `mongoexport/mongoimport` 适合 JSON/CSV 数据交换。
- `mongodump/mongorestore` 适合备份恢复，保留 BSON 类型信息更完整。

## 慢查询排查

执行计划：

```javascript
db.users.find({ status: "ACTIVE" })
  .sort({ createdAt: -1 })
  .explain("executionStats")
```

重点判断：

- 是否 `COLLSCAN`。
- `totalDocsExamined` 是否远大于返回数。
- 是否发生内存排序。
- 是否缺少复合索引。

常见修复：

```javascript
db.users.createIndex({ status: 1, createdAt: -1 })
```

## 查看集合统计

```javascript
db.users.stats()
```

常看：

- 文档数量。
- 集合大小。
- 索引大小。
- 平均文档大小。

## 查看数据库统计

```javascript
db.stats()
```

## 查看当前操作

```javascript
db.currentOp()
```

杀掉操作：

```javascript
db.killOp(opid)
```

注意：生产不要随意 kill，先确认来源、执行时间、是否阻塞业务。

## 性能优化清单

1. 核心查询必须有索引。
2. 用 projection 减少返回字段。
3. 避免深分页 `skip`。
4. 聚合里先 `$match` 再 `$group`。
5. 控制数组字段长度。
6. 避免频繁更新超大文档。
7. 写多读少字段谨慎建索引。
8. 批量写入用批处理。
9. 生产使用副本集。
10. 监控连接数、慢查询、磁盘、内存、锁等待。

## 生产安全

不要公网裸露 `27017`。

必须做：

- 开启认证。
- 使用强密码。
- 业务账号最小权限。
- 安全组或防火墙限制来源。
- 定期备份。
- 备份恢复要演练。
- 生产和测试环境隔离。

## 连接池建议

连接字符串示例：

```text
mongodb://user:password@host:27017/appdb?authSource=admin&connectTimeoutMS=3000&socketTimeoutMS=5000&maxPoolSize=50
```

建议：

- 明确连接超时。
- 明确读写超时。
- 明确连接池大小。
- 不要每个请求创建客户端。
- 高并发服务要观察连接池耗尽。

## 上线前检查

- 账号权限是否最小化。
- 是否有备份策略。
- 是否能恢复备份。
- 核心查询是否 explain 过。
- 是否有无用索引。
- 是否有深分页。
- 是否有无限增长数组。
- 是否有慢查询监控。
- 是否有磁盘容量告警。
- 是否使用副本集。

## 下一步

最后看常见坑和面试题：[[MongoDB 10 常见坑与面试题]]

