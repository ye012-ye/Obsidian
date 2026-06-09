---
title: tika-app 命令行工具
date: 2026-05-27
tags:
  - apache-tika
  - cli
aliases:
  - tika-app CLI
  - Tika 命令行
---

# 03 · 命令行工具 tika-app

> [!info] 上一篇 / 下一篇
> ← [[02 - 安装与环境配置]]　|　→ [[04 - Java API 入门]]

`tika-app` 是一个**可执行 fat jar**，让你不写一行代码就能用 Tika 所有功能。非常适合：

- 排查"这个文件为什么解析失败"
- 给 PM 演示
- 一次性脚本批处理
- 临时启动 REST 服务（`--server` 模式）

## 1. 拿到 jar

```bash
# 官网下载
wget https://dlcdn.apache.org/tika/3.2.3/tika-app-3.2.3.jar

# 或 Maven
mvn dependency:copy -Dartifact=org.apache.tika:tika-app:3.2.3
```

设个别名让命令短点：

```bash
alias tika='java -jar /path/to/tika-app-3.2.3.jar'
```

## 2. 五个最常用命令

| 命令 | 作用 |
|---|---|
| `tika --text file` | 抽纯文本 |
| `tika --metadata file` | 看元数据 |
| `tika --detect file` | 只检测 MIME 类型 |
| `tika --language file` | 检测语言 |
| `tika --xml file` | 抽带结构的 XHTML |

```bash
tika --text   report.pdf
tika --metadata report.pdf
tika --detect mystery.bin           # 输出 application/pdf
tika --language essay.txt           # 输出 en、zh-cn …
tika --xml    page.html  > out.xml
```

## 3. 输出格式选项

| 选项 | 输出 |
|------|------|
| `-t`, `--text` | 纯文本 |
| `-T`, `--text-main` | 主内容（自动去导航/页眉页脚） |
| `-x`, `--xml` | XHTML |
| `-h`, `--html` | HTML |
| `-j`, `--json` | JSON（text + metadata） |
| `-J`, `--jsonRecursive` | 递归 JSON（含嵌入文档） |
| `-m`, `--metadata` | 仅元数据 |
| `-m -j` | 元数据 JSON |

```bash
tika -J archive.zip > result.json    # ZIP 里每个文件单独一段
```

## 4. 批量处理（最实用）

```bash
# 把一个目录里所有文件抽成 txt，输出到另一个目录
java -jar tika-app-3.2.3.jar \
    --inputDir ./docs \
    --outputDir ./txt \
    --extract \
    -t
```

参数：

- `-i DIR` / `--inputDir DIR` — 输入目录（递归）
- `-o DIR` / `--outputDir DIR` — 输出目录
- `-z` / `--extract` — 嵌入文档也单独导出
- `--extractDir=DIR` — 嵌入文档输出目录

> [!tip] 真大批量用 tika-pipes
> CLI 适合千级文件，万级以上请改用 `tika-pipes`（多线程 + 断点续传 + 输出 Solr/ES/CSV）。

## 5. 启动 REST 服务

> 这是个常被忽略的功能 — tika-app 自带一个 server 模式。

```bash
java -jar tika-app-3.2.3.jar --server --port 9998
```

```bash
curl -T report.pdf http://localhost:9998/tika
curl -T report.pdf http://localhost:9998/meta
curl -T report.pdf http://localhost:9998/rmeta/text
```

正式生产环境请用专门的 `tika-server-standard.jar`，参见 [[13 - tika-server REST API]]。

## 6. GUI 模式（没参数就出图形界面）

```bash
java -jar tika-app-3.2.3.jar
```

会弹出一个 Swing 窗口，把文件拖进去就能看抽取结果，**非常适合给同事/客户做"现场演示"**。

## 7. 配置文件

复杂场景可以把配置写到 `tika-config.xml`：

```bash
tika --config=/path/to/tika-config.xml --text my.pdf
```

详细的配置语法在 [[11 - tika-config.xml 配置]]。

## 8. 调试模式

```bash
# 看用了哪个 Parser
tika -v --text report.pdf

# 列出所有支持的 MIME 类型
tika --list-supported-types

# 列出所有解析器和它们能处理的类型
tika --list-parsers
tika --list-parsers-details

# 列出所有检测器
tika --list-detectors
```

> [!example] 调试场景示例
> 你拿到一个客户的奇怪文件解析报错，先：
> ```bash
> tika --detect mystery.file        # 看 Tika 觉得它是什么
> tika -v --text mystery.file 2>&1  # 看抛栈是从哪个 Parser 出来的
> ```

## 9. 性能 / 内存调优

```bash
# 大文件加内存
java -Xms512m -Xmx4g -jar tika-app-3.2.3.jar --text huge.pdf

# 加超时（毫秒）
java -jar tika-app-3.2.3.jar --parseTimeoutMs=30000 --text slow.pdf
```

## 10. 速查表

```bash
# 看版本
tika --version

# 帮助
tika --help

# 抽取与导出（带嵌入）
tika -i ./in -o ./out -z

# 检测语言
tika --language file

# 只看 MIME
tika --detect file

# 启动 server
tika --server --port 9998

# 用自定义配置
tika --config=tika-config.xml -t file
```

---

下一步：[[04 - Java API 入门]] —— 把 Tika 真正写进代码。
