---
title: MongoDB使用方法
tags:
  - MongoDB
  - mgdb
  - 数据库
  - NoSQL
created: 2026-05-04
description: MongoDB 使用方法总览导航，按学习模块拆分
---

# MongoDB 使用方法

> [!note] 学习入口
> 原来一篇太长，不适合查阅。现在拆成模块，想学哪里直接进对应笔记。

## 学习顺序

1. [[MongoDB 01 基础概念与适用场景]]
2. [[MongoDB 02 本地环境与 mongosh]]
3. [[MongoDB 03 CRUD 与查询语法]]
4. [[MongoDB 04 索引与执行计划]]
5. [[MongoDB 05 聚合管道]]
6. [[MongoDB 06 事务与一致性]]
7. [[MongoDB 07 Java 与 Spring Boot 集成]]
8. [[MongoDB 08 文档建模设计]]
9. [[MongoDB 09 运维备份与性能排查]]
10. [[MongoDB 10 常见坑与面试题]]

## 按问题查

| 你想学什么 | 看哪篇 |
| --- | --- |
| MongoDB 是什么，和 MySQL 有什么区别 | [[MongoDB 01 基础概念与适用场景]] |
| 本地怎么装，怎么连库，怎么用命令行 | [[MongoDB 02 本地环境与 mongosh]] |
| 增删改查、条件查询、数组、嵌套字段 | [[MongoDB 03 CRUD 与查询语法]] |
| 查询慢、怎么建索引、怎么看 explain | [[MongoDB 04 索引与执行计划]] |
| 类似 group by、统计、报表、lookup | [[MongoDB 05 聚合管道]] |
| 事务、单文档原子性、多文档一致性 | [[MongoDB 06 事务与一致性]] |
| Java 驱动、Spring Boot、Repository、MongoTemplate | [[MongoDB 07 Java 与 Spring Boot 集成]] |
| 嵌入还是引用，订单、用户画像、日志怎么设计 | [[MongoDB 08 文档建模设计]] |
| 备份恢复、慢查询、生产排查 | [[MongoDB 09 运维备份与性能排查]] |
| 面试题、常见错误、上线避坑 | [[MongoDB 10 常见坑与面试题]] |

## 核心记忆

- MongoDB 是文档型数据库，核心是 database、collection、document。
- MongoDB 适合结构灵活、天然 JSON 化、围绕单个聚合根读写的数据。
- 不要把 MongoDB 当成“没有表结构的 MySQL”。
- 能用单文档表达的业务，不要拆成多个集合再靠事务拼起来。
- 查询性能主要靠正确建模 + 正确索引，不是 MongoDB 天然万能快。
- 生产必须关注认证、备份、索引、慢查询、连接池、副本集。

