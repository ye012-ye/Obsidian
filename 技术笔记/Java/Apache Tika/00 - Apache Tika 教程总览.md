---
title: Apache Tika 教程总览
date: 2026-05-27
tags:
  - apache-tika
  - java
  - moc
  - 内容提取
aliases:
  - Tika MOC
  - Tika 索引
  - Apache Tika 教程目录
cssclasses: []
---

# Apache Tika 教程总览（从 0 基础到大神）

> [!abstract] 这是什么
> Apache Tika 是一个内容分析工具包，能从 **1000+ 种文件格式**（PDF / Word / Excel / PPT / HTML / 图片 / 音视频 / 压缩包 / 邮件 / RSS …）中**统一**提取**纯文本**和**元数据**。
> 几乎所有的搜索引擎（Lucene/Solr/Elasticsearch）、RAG 系统、知识库、数据治理平台都靠它做"读文档"这一步。

> [!tip] 学习路径
> 按编号顺序阅读即可。前 4 篇是**入门**，5–11 是**核心 API**，12–14 是**服务化部署**，15–17 是**生产实践**，18–19 是**高阶进阶**。

---

## Part 1 · 入门篇（0 基础）

- [[01 - Tika 简介与核心概念]] — 三大核心：Parser / Detector / Metadata
- [[02 - 安装与环境配置]] — Maven / Gradle / 单 jar / Docker
- [[03 - 命令行工具 tika-app]] — 不写代码也能用
- [[04 - Java API 入门]] — 10 行代码读一个 PDF

## Part 2 · 核心 API（进阶）

- [[05 - 解析器 Parser 详解]] — AutoDetectParser、CompositeParser
- [[06 - 内容处理器 ContentHandler]] — BodyContentHandler、ToXMLContentHandler、自定义 SAX
- [[07 - 元数据 Metadata]] — Dublin Core、TIKA 命名空间、Property
- [[08 - 文件类型检测 Detector]] — MIME 魔数 / 后缀 / 容器检测
- [[09 - 语言检测]] — Optimaize / Lingo24 / OpenNLP
- [[10 - OCR 集成 Tesseract]] — 图片 / 扫描件 PDF
- [[11 - tika-config.xml 配置]] — 关解析器、限大小、自定义

## Part 3 · 服务化（部署）

- [[12 - 嵌入式文档与递归解析]] — 邮件附件、压缩包、Office 嵌图
- [[13 - tika-server REST API]] — HTTP 调用、跨语言
- [[14 - 各格式解析详解 PDF Office HTML]] — PDF / DOCX / XLSX / EML 调参

## Part 4 · 生产实践

- [[15 - 性能调优与最佳实践]] — 内存、超时、forking、批处理
- [[16 - Spring Boot 集成]] — Bean 注入、文件上传、流式
- [[17 - 异常处理与故障排查]] — TikaException、EncryptedDocumentException

## Part 5 · 大神进阶

- [[18 - 高级实战 - 全文检索集成]] — 接 Elasticsearch / Lucene
- [[19 - 大神进阶 - 自定义解析器开发]] — 实现自己的 Parser、SPI 注册

## 附录 · 拿来即用

- [[20 - 生产级通用提取器（拿来即用）]] — 把全系列焊成一个复制即用的 `TikaExtractor`（隔离 + 限额 + 超时 + 结构化结果 + 不崩）

---

## 速查卡

> [!info] 必背三件套
> ```java
> Parser parser   = new AutoDetectParser();   // 谁来解析
> ContentHandler h = new BodyContentHandler(-1); // 解析结果给谁
> Metadata meta   = new Metadata();           // 元数据给谁
> parser.parse(inputStream, h, meta, new ParseContext());
> String text = h.toString();
> ```

> [!example] CLI 一行命令
> ```bash
> java -jar tika-app-3.2.3.jar --text report.pdf
> java -jar tika-app-3.2.3.jar --metadata report.pdf
> java -jar tika-app-3.2.3.jar --language report.pdf
> java -jar tika-app-3.2.3.jar --server --port 9998
> ```

## 版本说明

- 本教程基于 **Apache Tika 3.2.x**（最新稳定线）
- Tika 3.x **要求 JDK 11+**，Tika 2.x 支持 JDK 8
- 1.x 已停止维护，新项目请直接用 3.x

## 官方资源

- 官网：https://tika.apache.org/
- Wiki：https://cwiki.apache.org/confluence/display/TIKA
- 源码：https://github.com/apache/tika

---

> [!quote] 学完你能干什么
> 写一个能"吃任何文件、吐出干净文本+元数据"的服务；为 RAG / 搜索引擎喂料；扫合规风险（隐藏作者、修订记录）；批量做 OCR；分析磁盘里十万个文档的语言分布……
