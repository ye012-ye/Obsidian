---
title: tika-server REST API
date: 2026-05-27
tags:
  - apache-tika
  - rest
  - microservice
aliases:
  - tika-server
  - Tika HTTP
---

# 13 · tika-server REST API

> [!info] 上一篇 / 下一篇
> ← [[12 - 嵌入式文档与递归解析]]　|　→ [[14 - 各格式解析详解 PDF Office HTML]]

`tika-server` 把 Tika 作为 **HTTP 微服务**对外暴露，任意语言都能调用：Python、Go、Node.js、PHP、shell …

## 1. 启动

### 1.1 单 jar

```bash
wget https://dlcdn.apache.org/tika/3.2.3/tika-server-standard-3.2.3.jar

java -jar tika-server-standard-3.2.3.jar
# 默认监听 0.0.0.0:9998
```

常用参数：

```bash
java -jar tika-server-standard-3.2.3.jar \
    --host 0.0.0.0 \
    --port 9998 \
    --config /etc/tika/tika-config.xml \
    --status      # 输出健康/统计
```

### 1.2 Docker（推荐）

```bash
docker run -d --name tika \
    -p 9998:9998 \
    apache/tika:3.2.3.0
```

带 OCR + 全套依赖：

```bash
docker run -d --name tika \
    -p 9998:9998 \
    apache/tika:3.2.3.0-full
```

挂载自定义配置：

```bash
docker run -d --name tika \
    -p 9998:9998 \
    -v $(pwd)/tika-config.xml:/tika-config.xml \
    apache/tika:3.2.3.0 \
    --config /tika-config.xml
```

## 2. 核心端点

| 路径 | 方法 | 作用 | 返回 |
|---|---|---|---|
| `/tika` | GET | 心跳 | 文本 |
| `/tika` | PUT/POST | 抽文本 | text/plain（默认）或 application/xhtml+xml |
| `/meta` | PUT/POST | 抽元数据 | text/csv 或 application/json |
| `/rmeta/text` | PUT/POST | **递归** + 元数据 + 文本 | application/json |
| `/rmeta/xml` | PUT/POST | 递归 + XHTML | application/json |
| `/rmeta/html` | PUT/POST | 递归 + HTML | application/json |
| `/detect/stream` | PUT | 检测 MIME | 文本 |
| `/language/stream` | PUT | 检测语言 | 文本 |
| `/unpack` | PUT | 拆嵌入文件 | application/zip |
| `/version` | GET | 版本 | 文本 |
| `/mime-types` | GET | 支持类型清单 | JSON/HTML |
| `/parsers` | GET | 解析器清单 | JSON/HTML |

## 3. 调用示例（curl）

### 3.1 抽文本

```bash
curl -T report.pdf http://localhost:9998/tika \
    -H "Accept: text/plain"
```

### 3.2 抽 XHTML（保留结构）

```bash
curl -T report.pdf http://localhost:9998/tika \
    -H "Accept: application/xhtml+xml"
```

### 3.3 抽元数据 JSON

```bash
curl -T report.pdf http://localhost:9998/meta \
    -H "Accept: application/json"
```

### 3.4 递归（最常用，邮件/压缩包）

```bash
curl -T email.eml http://localhost:9998/rmeta/text \
    -H "Accept: application/json"
```

返回 JSON 数组：

```json
[
  {
    "Content-Type": "message/rfc822",
    "subject": "Q1 Report",
    "X-TIKA:content": "邮件正文…"
  },
  {
    "Content-Type": "application/pdf",
    "resourceName": "report.pdf",
    "X-TIKA:content": "附件 PDF 文本…",
    "X-TIKA:embedded_depth": "1"
  }
]
```

### 3.5 检测 MIME

```bash
curl -T mystery.bin http://localhost:9998/detect/stream
# application/pdf
```

文件名当提示：

```bash
curl -T mystery.bin http://localhost:9998/detect/stream \
    -H "Content-Disposition: attachment; filename=report.pdf"
```

### 3.6 语言

```bash
curl -T essay.txt http://localhost:9998/language/stream
# en
```

### 3.7 解压嵌入文件

```bash
curl -T email.eml http://localhost:9998/unpack -o extracted.zip
```

## 4. 用 Python 调

`tika-python` 封装好了：

```bash
pip install tika
```

```python
from tika import parser
parsed = parser.from_file("report.pdf", "http://localhost:9998/tika")
print(parsed["metadata"])
print(parsed["content"])
```

也可以直接 `requests`：

```python
import requests, json

with open("report.pdf", "rb") as f:
    r = requests.put(
        "http://localhost:9998/rmeta/text",
        data=f,
        headers={"Accept": "application/json"},
        timeout=300,
    )
docs = r.json()
for d in docs:
    print(d.get("Content-Type"), d.get("X-TIKA:content", "")[:200])
```

## 5. 用 Node 调

```js
import axios from 'axios';
import fs from 'fs';

const res = await axios.put(
  'http://localhost:9998/rmeta/text',
  fs.createReadStream('report.pdf'),
  { headers: { Accept: 'application/json' }, maxContentLength: Infinity }
);
console.log(res.data);
```

## 6. 自定义请求头（控制 Tika 行为）

| Header | 作用 |
|---|---|
| `Content-Type: application/pdf` | 已知 MIME，跳过检测 |
| `Content-Disposition: attachment; filename=foo.pdf` | 给文件名提示 |
| `Accept: text/plain` / `application/json` / `application/xhtml+xml` | 输出格式 |
| `Accept-Language: zh-cn` | 输出文本语言提示 |
| `X-Tika-OCRLanguage: eng+chi_sim` | OCR 语言 |
| `X-Tika-PDFocrStrategy: ocr_and_text_extraction` | PDF OCR 策略 |
| `X-Tika-PDFextractInlineImages: false` | PDF 是否抽内嵌图 |
| `X-Tika-Skip-Embedded: true` | 跳过嵌入文档 |
| `X-Tika-Timeout-Millis: 60000` | 该请求超时 |

例：

```bash
curl -T scan.pdf http://localhost:9998/tika \
    -H "Accept: text/plain" \
    -H "X-Tika-OCRLanguage: eng+chi_sim" \
    -H "X-Tika-PDFocrStrategy: ocr_and_text_extraction"
```

## 7. 生产部署清单

- **资源**：每实例 1–2 vCPU、2–4 GB RAM 起；OCR 场景翻倍
- **隔离**：开 `--spawnChild`（旧版叫 `forking`），让每次请求在子 JVM 里跑（防止崩溃拖死服务）
- **超时**：`--taskTimeoutMillis=300000` + 网关层超时
- **反向代理**：Nginx / Envoy 加请求体大小限制 + rate limit
- **配置**：用 `--config` 把不安全的 Parser 关掉（见 [[11 - tika-config.xml 配置]]）
- **指标**：`/status` 端点 + Prometheus 抓
- **多实例**：无状态，水平扩展即可；用 K8s `Deployment + HPA`

### docker-compose 例子

```yaml
services:
  tika:
    image: apache/tika:3.2.3.0-full
    ports:
      - "9998:9998"
    volumes:
      - ./tika-config.xml:/tika-config.xml:ro
    command:
      - "--host"
      - "0.0.0.0"
      - "--config"
      - "/tika-config.xml"
      - "--spawnChild"
      - "--taskTimeoutMillis"
      - "300000"
    deploy:
      resources:
        limits:
          memory: 4G
    restart: unless-stopped
```

## 8. 安全清单

- ❌ 不要把 tika-server **直接暴露公网**
- ✅ 放在 VPC / K8s 内部网络
- ✅ 网关上做认证（Tika 本身**没有内置鉴权**）
- ✅ 文件大小限制（Nginx `client_max_body_size`）
- ✅ MIME 白名单（用 `--config` 限制 Parser）
- ✅ 关掉 `ExecutableParser`、`SQLite3Parser` 等
- ✅ 启用 `--spawnChild`，避免一个坏请求挂掉所有

## 9. 常见错误

| 错误 | 原因 | 解决 |
|---|---|---|
| 415 Unsupported Media Type | 没设 `Content-Type` 或类型未支持 | 加 Header 或换文件 |
| 422 Unprocessable Entity | Tika 抛 TikaException | 看 server 日志，可能加密或损坏 |
| 503 Service Unavailable | server 在重启子进程 | 加超时和重试 |
| 408 Request Timeout | 超过 `--taskTimeoutMillis` | 调大或拆文件 |

---

下一步：[[14 - 各格式解析详解 PDF Office HTML]] —— 把每类格式的"调参旋钮"全讲清。
