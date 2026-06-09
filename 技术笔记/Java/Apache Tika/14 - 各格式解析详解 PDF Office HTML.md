---
title: 各格式解析详解 PDF Office HTML
date: 2026-05-27
tags:
  - apache-tika
  - pdf
  - office
  - html
aliases:
  - PDFParserConfig
  - OfficeParserConfig
  - HtmlParser
---

# 14 · 各格式解析详解（PDF / Office / HTML / Email / Image）

> [!info] 上一篇 / 下一篇
> ← [[13 - tika-server REST API]]　|　→ [[15 - 性能调优与最佳实践]]

每类格式都有自己的"调参旋钮"。这一篇是**速查手册**。

## 1. PDF（PDFParser）

### 1.1 配置

```java
import org.apache.tika.parser.pdf.PDFParserConfig;

PDFParserConfig c = new PDFParserConfig();

// 文本抽取
c.setSortByPosition(true);              // 按视觉位置排序（多栏排版更准）
c.setSuppressDuplicateOverlappingText(true);
c.setEnableAutoSpace(true);             // 自动补空格

// 注释 / 表单
c.setExtractAnnotationText(true);
c.setExtractAcroFormContent(true);
c.setExtractActions(false);

// 嵌入图片 / 文件
c.setExtractInlineImages(false);
c.setExtractUniqueInlineImagesOnly(true);
c.setExtractFontNames(false);

// 段落 / 标记
c.setExtractMarkedContent(false);
c.setExtractBookmarksText(true);

// OCR（见 [[10 - OCR 集成 Tesseract]]）
c.setOcrStrategy(PDFParserConfig.OCR_STRATEGY.AUTO);
c.setOcrDPI(300);
c.setOcrImageType(org.apache.tika.parser.pdf.ImageType.GRAY);
c.setOcrImageFormatName("png");

// 容错
c.setCatchIntermediateIOExceptions(true);  // 单页错误不中断整文档
c.setIfXFAExtractOnlyXFA(false);

ParseContext ctx = new ParseContext();
ctx.set(PDFParserConfig.class, c);
```

### 1.2 PDF 常见 Metadata

```
pdf:PDFVersion                = 1.7
pdf:producer                  = Microsoft® Word
xmp:CreatorTool               = Microsoft® Word
xmpTPg:NPages                 = 23
pdf:hasMarkedContent          = true
pdf:encrypted                 = false
pdf:hasXMP                    = true
pdf:hasXFA                    = false
pdf:hasCollection             = false
pdf:overallPercentageUnmappedUnicodeChars = 0.0
access_permission:*           = 一系列权限位
```

### 1.3 加密 PDF

```java
import org.apache.tika.parser.PasswordProvider;

ctx.set(PasswordProvider.class, metadata -> "my-password");
```

无法解密会抛 `EncryptedDocumentException`，详见 [[17 - 异常处理与故障排查]]。

### 1.4 PDF/A、PDF/X 与"扫描件"PDF

- **PDF/A**：归档用，正常文本，无需 OCR
- **PDF/X**：印刷用，多用 CMYK，文本抽取通常正常
- **扫描件 PDF**：仅图像，**必须 OCR**。判断方法：抽完文本如果只有空白或极少字符，但文件大→大概率扫描件。

## 2. Office 老格式（OfficeParser，.doc/.xls/.ppt）

```java
import org.apache.tika.parser.microsoft.OfficeParserConfig;

OfficeParserConfig c = new OfficeParserConfig();
c.setExtractMacros(false);              // 安全：不抽 VBA 宏代码
c.setIncludeDeletedContent(false);      // 不抽"已删除"文本
c.setIncludeMoveFromContent(false);
c.setIncludeShapeBasedContent(true);    // 形状里的文字
c.setIncludeHeadersAndFooters(true);
c.setConcatenatePhoneticRuns(true);     // 日语注音

ParseContext ctx = new ParseContext();
ctx.set(OfficeParserConfig.class, c);
```

### Excel 调优

```java
c.setExtractAllAlternativesFromMSG(false);
c.setIncludeMissingRows(false);
c.setIncludeHeadersAndFooters(true);
```

> [!tip] Excel 大表
> 默认 SAX 流式解析，**不会一次性把 sheet 装内存**。但公式计算和共享字符串表仍占内存。超大 xlsx 推荐 `useSAXDocxExtractor=true`（默认就是）。

## 3. OOXML（OOXMLParser，.docx/.xlsx/.pptx）

OOXML 用同一份 `OfficeParserConfig`：

```java
OfficeParserConfig c = new OfficeParserConfig();
c.setUseSAXDocxExtractor(true);         // SAX 流式（推荐）
c.setUseSAXPptxExtractor(true);
c.setExtractAllAlternativesFromMSG(false);
ctx.set(OfficeParserConfig.class, c);
```

### Word docx 常见 Metadata

```
extended-properties:Application = Microsoft Office Word
extended-properties:Company     = ACME
meta:word-count                 = 1832
meta:page-count                 = 6
meta:character-count            = 9821
meta:last-author                = bob
custom:CompanyName              = ACME
```

### PowerPoint 取每页幻灯片

用 `ToXMLContentHandler`，每个 `<div class="slide-content">` 是一页：

```java
ToXMLContentHandler h = new ToXMLContentHandler("UTF-8");
parser.parse(in, h, meta, ctx);
String xhtml = h.toString();
// 用 jsoup 拆 div.slide-content
```

## 4. HTML（HtmlParser）

```java
import org.apache.tika.parser.html.HtmlMapper;
import org.apache.tika.parser.html.DefaultHtmlMapper;
import org.apache.tika.parser.html.IdentityHtmlMapper;

// 默认：HTML5 → XHTML，去掉脚本/样式
ctx.set(HtmlMapper.class, DefaultHtmlMapper.INSTANCE);

// 或：保留原汁原味（不做映射）
ctx.set(HtmlMapper.class, new IdentityHtmlMapper());

// 自定义：只保留 <article> 内
class ArticleOnlyMapper extends DefaultHtmlMapper {
    @Override
    public String mapSafeElement(String name) {
        return "article".equalsIgnoreCase(name) ? "article" : super.mapSafeElement(name);
    }
}
```

### 编码处理

HTML 编码识别用 **3 路并发**：HTTP header → `<meta charset>` → ICU 字符集检测。一般不用管。**自己很确定**时可以传：

```java
meta.set(Metadata.CONTENT_TYPE, "text/html; charset=GB18030");
```

### 抽链接

```java
LinkContentHandler links = new LinkContentHandler();
parser.parse(in, links, meta, ctx);
links.getLinks().forEach(l -> System.out.println(l.getUri()));
```

### "去导航"提取正文（Boilerpipe）

```xml
<dependency>
    <groupId>org.apache.tika</groupId>
    <artifactId>tika-parser-html-commons-module</artifactId>
    <version>3.2.3</version>
</dependency>
```

```java
import org.apache.tika.parser.html.BoilerpipeContentHandler;

BoilerpipeContentHandler bp = new BoilerpipeContentHandler(new BodyContentHandler(-1));
parser.parse(in, bp, meta, ctx);
String main = bp.getTextDocument().getText(true, false);
```

## 5. 邮件（RFC822Parser / OutlookExtractor）

```java
// EML
// 自动识别 message/rfc822 → 用 RFC822Parser
// MSG（Outlook）→ application/vnd.ms-outlook → OutlookExtractor

// Metadata 上常见
meta.get(Message.MESSAGE_FROM);
meta.get(Message.MESSAGE_TO);
meta.get(Message.MESSAGE_CC);
meta.get(Message.MESSAGE_SUBJECT);
meta.get(TikaCoreProperties.CREATED);
```

要拿到附件列表，用 RecursiveParserWrapper（[[12 - 嵌入式文档与递归解析]]）。

### .msg 的特殊配置

```java
import org.apache.tika.parser.microsoft.OfficeParserConfig;

OfficeParserConfig c = new OfficeParserConfig();
c.setExtractAllAlternativesFromMSG(true);   // 同时拿 plain / html / rtf
ctx.set(OfficeParserConfig.class, c);
```

## 6. 图片（EXIF / IPTC / XMP）

```java
import org.apache.tika.parser.image.ImageParser;

// 通常用 AutoDetectParser，但 EXIF 由 JempboxExtractor / metadata-extractor 处理
// 常见 Metadata：
meta.get("Image Width");
meta.get("Image Height");
meta.get("Model");                      // 相机型号
meta.get("Date/Time Original");
meta.get("GPS Latitude");
meta.get("GPS Longitude");
meta.get("Software");
meta.get("Color Space");
```

> [!warning] 用户上传图片务必清 EXIF
> 隐藏 GPS、设备 ID、原始时间戳。Tika 只读，要写需用 `metadata-extractor` 反向操作或 `exiftool`。

## 7. 音视频

```java
// MP3
meta.get(XMPDM.GENRE);
meta.get(XMPDM.ARTIST);
meta.get(XMPDM.ALBUM);
meta.get(XMPDM.DURATION);

// MP4 / MOV
meta.get(TikaCoreProperties.CREATED);
meta.get("xmpDM:duration");
meta.get("tiff:ImageWidth");
```

> 视频的"内容"Tika 抽不出（不是 ASR）。只给元数据。

## 8. 压缩包

```java
// ZIP / TAR / 7z / RAR / GZIP / BZ2
// 默认会递归解每个内部文件
// 注意防 zip bomb：
ctx.set(AutoDetectParserConfig.class,
    new AutoDetectParserConfig().setMaxEmbeddedResources(200L));
```

## 9. 一张速查表：哪些 Config 类要记

| 类 | 控制 |
|---|---|
| `PDFParserConfig` | PDF 全部行为 |
| `OfficeParserConfig` | .doc/.xls/.ppt 和 .docx/.xlsx/.pptx |
| `TesseractOCRConfig` | OCR |
| `HtmlMapper` | HTML 元素映射 |
| `AutoDetectParserConfig` | 写入字符上限、嵌入资源上限 |
| `PasswordProvider` | 加密文档密码 |

每个都通过 `ParseContext.set()` 注入。

---

下一步：[[15 - 性能调优与最佳实践]] —— 让 Tika 在生产里跑得稳又快。
