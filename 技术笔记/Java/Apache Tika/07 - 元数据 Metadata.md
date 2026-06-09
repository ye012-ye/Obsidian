---
title: Tika Metadata 详解
date: 2026-05-27
tags:
  - apache-tika
  - metadata
aliases:
  - TikaCoreProperties
  - Dublin Core
  - 元数据提取
---

# 07 · 元数据 Metadata

> [!info] 上一篇 / 下一篇
> ← [[06 - 内容处理器 ContentHandler]]　|　→ [[08 - 文件类型检测 Detector]]

`Metadata` 是 Tika 装属性的篮子。本质是 `Map<String, String[]>`（一个键可对应多个值，比如多作者）。

## 1. 基本读写

```java
Metadata m = new Metadata();

// 读
m.get("Content-Type");
m.get(TikaCoreProperties.TITLE);
m.getValues("dc:creator");     // String[]
String[] names = m.names();    // 拿到所有键

// 写（一般 Parser 自己写；你也可以预先写文件名提示）
m.set(TikaCoreProperties.RESOURCE_NAME_KEY, "report.pdf");
m.add(TikaCoreProperties.CREATOR, "Alice");
m.add(TikaCoreProperties.CREATOR, "Bob");
```

## 2. 关键的"提示型"元数据

> 这些在 parse 之前**主动设置**会帮 Tika 提高准确率。

| 键 | 用处 |
|---|---|
| `TikaCoreProperties.RESOURCE_NAME_KEY`（`resourceName`） | 文件名，辅助 MIME 检测 |
| `Metadata.CONTENT_TYPE`（`Content-Type`） | 已知 MIME，跳过检测 |
| `Metadata.CONTENT_ENCODING` | 已知编码（HTML/TXT） |
| `Metadata.CONTENT_LENGTH` | 文件大小 |

```java
m.set(TikaCoreProperties.RESOURCE_NAME_KEY, fileName);
m.set(Metadata.CONTENT_TYPE, "application/pdf");
m.set(Metadata.CONTENT_LENGTH, String.valueOf(size));
```

## 3. 标准命名空间

Tika 用了 **Dublin Core / XMP / 自家命名空间** 三套。常见的：

### 3.1 通用（TikaCoreProperties）

```java
TikaCoreProperties.TITLE                  // dc:title
TikaCoreProperties.CREATOR                // dc:creator
TikaCoreProperties.SUBJECT                // dc:subject / keywords
TikaCoreProperties.DESCRIPTION            // dc:description
TikaCoreProperties.CREATED                // 创建时间（Date）
TikaCoreProperties.MODIFIED               // 修改时间
TikaCoreProperties.LANGUAGE               // 语言
TikaCoreProperties.COMMENTS
TikaCoreProperties.PUBLISHER
TikaCoreProperties.IDENTIFIER
TikaCoreProperties.RESOURCE_NAME_KEY      // 文件名
```

### 3.2 Office 专用（Office）

```java
Office.AUTHOR
Office.LAST_AUTHOR
Office.WORD_COUNT
Office.PAGE_COUNT
Office.CHARACTER_COUNT
Office.PARAGRAPH_COUNT
Office.SLIDE_COUNT
```

### 3.3 PDF 专用（PDF）

```java
PDF.PDF_VERSION
PDF.PRODUCER                              // 生成工具，如 "Microsoft Word"
PDF.HAS_FORM
PDF.HAS_SIGNATURE
PDF.DOC_INFO_CREATOR_TOOL                 // 创建工具
PDF.IS_ENCRYPTED
```

### 3.4 图片 / EXIF（TIFF / EXIF）

```java
TIFF.IMAGE_WIDTH
TIFF.IMAGE_LENGTH
TIFF.BITS_PER_SAMPLE
TIFF.COMPRESSION
TIFF.RESOLUTION_UNIT

// EXIF 在 Tika 里属于 IPTC/XMP，键长这样：
m.get("Model")                            // 相机型号 "Canon EOS R5"
m.get("GPS Latitude")
m.get("Exposure Time")
```

### 3.5 邮件（Message）

```java
Message.MESSAGE_FROM
Message.MESSAGE_TO
Message.MESSAGE_CC
Message.MESSAGE_SUBJECT
TikaCoreProperties.CREATED                // 发件时间
```

## 4. 完整打印所有键

调试神器：

```java
for (String name : meta.names()) {
    System.out.printf("%-40s = %s%n",
            name, String.join("|", meta.getValues(name)));
}
```

## 5. 强类型读取 — Property API

字符串键不爽？用 `Property`：

```java
Date created = meta.getDate(TikaCoreProperties.CREATED);
Integer pages = meta.getInt(PagedText.N_PAGES);
String[] creators = meta.getValues(TikaCoreProperties.CREATOR);
```

## 6. Content-Type 长什么样

不是只有 MIME，还可能带参数：

```
application/pdf
text/html; charset=UTF-8
application/vnd.openxmlformats-officedocument.wordprocessingml.document
message/rfc822
image/jpeg
```

剥掉参数：

```java
import org.apache.tika.mime.MediaType;

String raw = meta.get(Metadata.CONTENT_TYPE);
MediaType mt = MediaType.parse(raw);
String baseType = mt.getBaseType().toString();  // "text/html"
String charset = mt.getParameters().get("charset");
```

## 7. 实用片段：把 Metadata 转成 Map / JSON

```java
public static Map<String, Object> toMap(Metadata m) {
    Map<String, Object> out = new LinkedHashMap<>();
    for (String name : m.names()) {
        String[] vals = m.getValues(name);
        out.put(name, vals.length == 1 ? vals[0] : Arrays.asList(vals));
    }
    return out;
}
```

```java
String json = new ObjectMapper().writeValueAsString(toMap(meta));
```

或用 Tika 自带：

```java
import org.apache.tika.metadata.serialization.JsonMetadata;

StringWriter sw = new StringWriter();
JsonMetadata.toJson(meta, sw);
String json = sw.toString();
```

## 8. 常见 Metadata 案例

### PDF
```
Content-Type           = application/pdf
xmpTPg:NPages          = 17
pdf:PDFVersion         = 1.7
pdf:producer           = Microsoft® Word 2019
xmp:CreatorTool        = Microsoft® Word 2019
dc:creator             = Alice Wang
dc:title               = 2025 Q1 Earnings
Creation-Date          = 2025-04-10T08:23:15Z
Last-Modified          = 2025-04-12T01:02:33Z
pdf:hasMarkedContent   = true
```

### DOCX
```
Content-Type           = application/vnd.openxmlformats-officedocument.wordprocessingml.document
extended-properties:Application = Microsoft Office Word
meta:word-count        = 1843
meta:character-count   = 9821
meta:page-count        = 6
meta:last-author       = bob
custom:CompanyName     = ACME
```

### JPEG 照片
```
Content-Type           = image/jpeg
Image Width            = 6000 pixels
Image Height           = 4000 pixels
Model                  = Canon EOS R5
Make                   = Canon
GPS Latitude           = 31° 14' 5.7"
GPS Longitude          = 121° 28' 51.4"
Date/Time              = 2025:08:21 14:23:11
```

### 邮件 EML
```
Content-Type           = message/rfc822
Message-From           = alice@x.com
Message-To             = bob@y.com
subject                = Re: 报销
Message-ID             = <abc@x.com>
```

## 9. 用元数据"挖矿"的典型应用

- **合规扫描**：找 `xmp:CreatorTool` 还残留前公司的人名
- **隐藏作者**：`meta:last-author` 暴露真实修改者
- **取证**：JPEG 的 `GPS *` 泄露拍摄地点
- **数据资产盘点**：按 `Content-Type` 统计各格式文件占比
- **PDF 真伪**：`pdf:producer` 看是不是从 Word 转的

---

下一步：[[08 - 文件类型检测 Detector]] —— 不靠后缀的 MIME 识别。
