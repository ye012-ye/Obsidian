---
title: Tika OCR 集成 Tesseract
date: 2026-05-27
tags:
  - apache-tika
  - ocr
  - tesseract
aliases:
  - TesseractOCRParser
  - 扫描件识别
---

# 10 · OCR 集成 Tesseract

> [!info] 上一篇 / 下一篇
> ← [[09 - 语言检测]]　|　→ [[11 - tika-config.xml 配置]]

Tika 自带 `TesseractOCRParser`，**但 Tesseract 引擎本身不在 jar 里**，你需要在系统里装好 `tesseract` 可执行文件。

## 1. 装 Tesseract

```bash
# Ubuntu/Debian
sudo apt-get install tesseract-ocr tesseract-ocr-eng tesseract-ocr-chi-sim

# macOS
brew install tesseract tesseract-lang

# Windows
# https://github.com/UB-Mannheim/tesseract/wiki  装完把安装目录加进 PATH
```

验证：

```bash
tesseract --version
tesseract --list-langs       # 看安装了哪些语言
```

> 必要语言：`eng`（英文）、`chi_sim`（简体）、`chi_tra`（繁体）、`jpn`（日文）等。

## 2. Tika 默认会做什么

- 看到图片 (`image/jpeg`、`image/png`、`image/tiff`、`image/bmp` 等) 会自动调 OCR
- 看到 PDF 时**默认 NOT OCR**（只抽真实文字层）— 需要显式打开
- 找不到 `tesseract` 命令时**静默跳过**（只警告日志）

## 3. 配置 OCR — TesseractOCRConfig

```java
import org.apache.tika.parser.ocr.TesseractOCRConfig;

TesseractOCRConfig ocr = new TesseractOCRConfig();
ocr.setLanguage("eng+chi_sim");          // 多语言用 + 连接
ocr.setMinFileSizeToOcr(1000);           // 小于 1KB 的图不做 OCR
ocr.setMaxFileSizeToOcr(20_000_000);     // 大于 20MB 跳过
ocr.setSkipOcr(false);                   // false = 做；true = 全局禁
ocr.setTimeoutSeconds(120);
ocr.setOutputType(TesseractOCRConfig.OUTPUT_TYPE.TXT);   // TXT / HOCR

// 如果 tesseract 不在 PATH 里
ocr.setTesseractPath("/opt/homebrew/bin/");

ParseContext ctx = new ParseContext();
ctx.set(TesseractOCRConfig.class, ocr);
```

## 4. 让 PDF 也做 OCR

```java
import org.apache.tika.parser.pdf.PDFParserConfig;

PDFParserConfig pdfCfg = new PDFParserConfig();
pdfCfg.setOcrStrategy(PDFParserConfig.OCR_STRATEGY.OCR_AND_TEXT_EXTRACTION);
// 也可以选：
// NO_OCR           - 不做 OCR（默认）
// OCR_ONLY         - 强制 OCR
// AUTO             - Tika 觉得需要才做
// OCR_AND_TEXT_EXTRACTION - 两份都拿

pdfCfg.setOcrDPI(300);                   // 渲染分辨率
pdfCfg.setOcrImageType(org.apache.tika.parser.pdf.ImageType.GRAY);
pdfCfg.setOcrImageFormatName("png");

ctx.set(PDFParserConfig.class, pdfCfg);
```

## 5. 完整示例：扫描件 PDF → 文本

```java
import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.parser.Parser;
import org.apache.tika.parser.ocr.TesseractOCRConfig;
import org.apache.tika.parser.pdf.PDFParserConfig;
import org.apache.tika.sax.BodyContentHandler;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

public class OcrDemo {
    public static void main(String[] args) throws Exception {
        Path file = Path.of(args[0]);

        Parser parser = new AutoDetectParser();
        BodyContentHandler handler = new BodyContentHandler(-1);
        Metadata meta = new Metadata();
        ParseContext ctx = new ParseContext();

        // 1) 让嵌入文档复用 parser
        ctx.set(Parser.class, parser);

        // 2) OCR
        TesseractOCRConfig ocr = new TesseractOCRConfig();
        ocr.setLanguage("eng+chi_sim");
        ocr.setTimeoutSeconds(180);
        ctx.set(TesseractOCRConfig.class, ocr);

        // 3) PDF 走 OCR + 抽文字
        PDFParserConfig pdfCfg = new PDFParserConfig();
        pdfCfg.setOcrStrategy(PDFParserConfig.OCR_STRATEGY.OCR_AND_TEXT_EXTRACTION);
        pdfCfg.setOcrDPI(300);
        ctx.set(PDFParserConfig.class, pdfCfg);

        try (InputStream in = Files.newInputStream(file)) {
            parser.parse(in, handler, meta, ctx);
        }

        System.out.println(handler.toString());
    }
}
```

## 6. 通过 tika-config.xml 配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser"/>
        <parser class="org.apache.tika.parser.ocr.TesseractOCRParser">
            <params>
                <param name="language" type="string">eng+chi_sim</param>
                <param name="minFileSizeToOcr" type="int">1000</param>
                <param name="maxFileSizeToOcr" type="int">20000000</param>
                <param name="timeoutSeconds" type="int">120</param>
            </params>
        </parser>
        <parser class="org.apache.tika.parser.pdf.PDFParser">
            <params>
                <param name="ocrStrategy" type="string">ocr_and_text_extraction</param>
                <param name="ocrDPI" type="int">300</param>
            </params>
        </parser>
    </parsers>
</properties>
```

```java
TikaConfig cfg = new TikaConfig("tika-config.xml");
Parser parser = new AutoDetectParser(cfg);
```

详见 [[11 - tika-config.xml 配置]]。

## 7. 性能调优要点

| 参数 | 影响 |
|---|---|
| `ocrDPI` | 越高越准但越慢；300 是甜点；600 仅极端情况 |
| `language` | 多语言累加会变慢；只放真正需要的 |
| `OCR_STRATEGY.AUTO` | 先看 PDF 是不是空文字层，再决定要不要 OCR — 平衡选项 |
| `minFileSizeToOcr` | 防小图（图标、logo）浪费时间 |
| `maxFileSizeToOcr` | 防超大图压垮 |
| `setOcrImageType(GRAY)` | 灰度图比 RGB 小且对 Tesseract 更友好 |
| `tesseract --oem 1` | LSTM 引擎更准（Tesseract 4+ 默认就是） |

## 8. 给 Tesseract 传额外参数

通过 `addOtherTesseractConfig`：

```java
ocr.addOtherTesseractConfig("preserve_interword_spaces", "1");
ocr.addOtherTesseractConfig("user_defined_dpi", "300");
```

## 9. 用 Docker 完整开箱

```bash
docker run -d --name tika -p 9998:9998 apache/tika:3.2.3.0-full
# `-full` tag 已经装好 tesseract + 多语言包
```

REST 调用见 [[13 - tika-server REST API]]。

## 10. 常见问题

> [!bug] OCR 没生效
> - 命令行能 `tesseract --version`？把 PATH 同步给 Java 进程
> - 看日志有没有 `Could not run Tesseract`
> - 显式 `setTesseractPath("/usr/local/bin/")`

> [!bug] 中文识别为乱码
> - 没装 `chi_sim` / `chi_tra` 语言包
> - `language` 没设成 `chi_sim`（或加 `+eng`）
> - 字体太小：把 `ocrDPI` 提到 400+

> [!bug] OOM
> 大 PDF 全 OCR 很吃内存。先用 `ImageMagick` 切页，或改用 `OCR_STRATEGY.AUTO`，或对每页单独 OCR。

> [!warning] 速度太慢
> Tesseract 是 CPU 密集型。对**单文件**没办法多核（Tesseract 单进程单线程），但**多文件**可以并行（线程池里给不同文件分进程）。

---

下一步：[[11 - tika-config.xml 配置]] —— 不写 Java 也能改 Tika 行为。
