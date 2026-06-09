---
title: MongoDB 02 本地环境与 mongosh
tags:
  - MongoDB
  - Docker
  - mongosh
created: 2026-05-04
up: "[[MongoDB使用方法]]"
---

# MongoDB 02 本地环境与 mongosh

## Docker 快速启动

无认证开发环境：

```bash
docker run --name mongodb -p 27017:27017 -d mongodb/mongodb-community-server:latest
```

查看：

```bash
docker ps
docker logs mongodb
```

停止删除：

```bash
docker stop mongodb
docker rm mongodb
```

## 持久化数据

```bash
docker run --name mongodb \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  -d mongodb/mongodb-community-server:latest
```

Windows PowerShell：

```powershell
docker run --name mongodb `
  -p 27017:27017 `
  -v mongodb_data:/data/db `
  -d mongodb/mongodb-community-server:latest
```

## 带账号密码启动

```bash
docker run --name mongodb \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  -e MONGODB_INITDB_ROOT_USERNAME=root \
  -e MONGODB_INITDB_ROOT_PASSWORD=123456 \
  -d mongodb/mongodb-community-server:latest
```

连接字符串：

```text
mongodb://root:123456@localhost:27017/admin
```

注意：

- `admin` 是认证库。
- 业务库可以是 `appdb`。
- 如果业务库是 `appdb`，账号在 `admin`，连接常写成 `mongodb://root:123456@localhost:27017/appdb?authSource=admin`。

## Docker Compose

```yaml
services:
  mongodb:
    image: mongodb/mongodb-community-server:latest
    container_name: mongodb
    ports:
      - "27017:27017"
    environment:
      MONGODB_INITDB_ROOT_USERNAME: root
      MONGODB_INITDB_ROOT_PASSWORD: 123456
    volumes:
      - mongodb_data:/data/db

volumes:
  mongodb_data:
```

启动：

```bash
docker compose up -d
```

停止：

```bash
docker compose down
```

## mongosh 连接

无认证：

```bash
mongosh "mongodb://localhost:27017"
```

有认证：

```bash
mongosh "mongodb://root:123456@localhost:27017/admin"
```

连接业务库：

```bash
mongosh "mongodb://root:123456@localhost:27017/appdb?authSource=admin"
```

## mongosh 常用命令

查看当前数据库：

```javascript
db
```

查看所有数据库：

```javascript
show dbs
```

切换数据库：

```javascript
use appdb
```

查看集合：

```javascript
show collections
```

创建集合：

```javascript
db.createCollection("users")
```

删除集合：

```javascript
db.users.drop()
```

删除当前数据库：

```javascript
db.dropDatabase()
```

## 创建普通业务账号

先用 root 连接，再切换到业务库：

```javascript
use appdb
```

创建读写账号：

```javascript
db.createUser({
  user: "app_user",
  pwd: "app_password",
  roles: [
    { role: "readWrite", db: "appdb" }
  ]
})
```

业务连接字符串：

```text
mongodb://app_user:app_password@localhost:27017/appdb
```

## 连接字符串常用参数

```text
mongodb://user:password@host:27017/appdb?authSource=admin&connectTimeoutMS=3000&socketTimeoutMS=5000&maxPoolSize=50
```

| 参数 | 说明 |
| --- | --- |
| `authSource` | 认证库 |
| `connectTimeoutMS` | 建立连接超时 |
| `socketTimeoutMS` | 读写超时 |
| `maxPoolSize` | 最大连接池大小 |
| `replicaSet` | 副本集名称 |
| `retryWrites` | 是否启用可重试写 |
| `readPreference` | 读偏好 |

## 常见连接问题

### 认证库错误

如果用户创建在 `admin`，但连接业务库时没带 `authSource=admin`，就容易认证失败。

正确：

```text
mongodb://root:123456@localhost:27017/appdb?authSource=admin
```

### 容器端口没映射

检查：

```bash
docker ps
```

确认有：

```text
0.0.0.0:27017->27017/tcp
```

### 密码特殊字符

密码里有 `@`、`:`、`/`、`?` 等字符时，需要 URL encode。

## 下一步

开始写数据和查数据：[[MongoDB 03 CRUD 与查询语法]]

