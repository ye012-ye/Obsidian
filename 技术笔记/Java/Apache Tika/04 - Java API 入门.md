---
title: Tika Java API 入门
date: 2026-05-27
tags:
  - apache-tika
  - java
  - 入门
aliases:
  - Tika 第一行代码
  - Tika facade
---

# 04 · Java API 入门

> [!info] 上一篇 / 下一篇
> ← [[03 - 命令行工具 tika-app]]　|　→ [[05 - 解析器 Parser 详解]]

Tika 有**两层 API**：

- 🟢 **Facade `Tika` 类** — 一行代码搞定 80% 场景
- 🔵 **底层 `Parser` API** — 拿到完整控制权（流式处理、自定义 Handler、嵌入文档等）

新手先用 Facade，需要更多控制再下沉。

## 1. 最简：Facade 一行代码

```java
import org.apache.tika.Tika;
import java.io.File;

public class Hello {
    public static void main(String[] args) throws Exception {
        Tika tika = new Tika();

        String text = tika.parseToString(new File("report.pdf"));
        System.out.println(text);

        String mime = tika.detect(new File("mystery.bin"));
        System.out.println(mime);                 // application/pdf
    }
}
```

> [!warning] Facade 默认有字符上限
> `Tika#parseToString()` 默认只返回前 **100,000 个字符**，超出会被截断。要处理超长文档：
> ```java
> Tika tika = new Tika();
> tika.setMaxStringLength(-1);          // 不限制
> ```
> 但**不限制 = 全部进内存**，大文件请用第 3 节的流式 API。

## 2. Facade 能做什么

```java
Tika tika = new Tika();

// 抽文本
String text = tika.parseToString(file);
String text2 = tika.parseToString(inputStream);
String text3 = tika.parseToString(url);

// 检测 MIME
String mime = tika.detect(file);
String mime2 = tika.detect(inputStream);
String mime3 = tika.detect("xxx.pdf");           // 仅看后缀
String mime4 = tika.detect(bytes);

// 同时拿元数据
Metadata meta = new Metadata();
try (Reader r = tika.parse(file, meta)) {
    char[] buf = new char[8192];
    int n; while ((n = r.read(buf)) != -1) { /* 流式消费 */ }
}
System.out.println(meta.get("Content-Type"));
System.out.println(meta.get(TikaCoreProperties.TITLE));
```

## 3. 标准模板（推荐生产用）

```java
import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.parser.Parser;
import org.apache.tika.sax.BodyContentHandler;
import org.xml.sax.ContentHandler;

import java.io.InputStream;

public class TikaExtract {
    private final Parser parser = new AutoDetectParser();

    public ExtractResult extract(InputStream in, String fileNameHint) throws Exception {
        // -1 = 不限字符数；生产里设个上限更安全，如 10_000_000
        ContentHandler handler = new BodyContentHandler(-1);
        Metadata metadata = new Metadata();
        if (fileNameHint != null) {
            metadata.set(TikaCoreProperties.RESOURCE_NAME_KEY, fileNameHint);
        }
        ParseContext ctx = new ParseContext();
        // 把同一个 parser 放进 context，嵌入文档会复用它
        ctx.set(Parser.class, parser);

        parser.parse(in, handler, metadata, ctx);

        return new ExtractResult(handler.toString(), metadata);
    }

    public record ExtractResult(String text, Metadata metadata) {}
}
```

### 三件套都做了什么

| 对象 | 类比 |
|------|------|
| `Parser parser` | 调度员 + 工人 |
| `ContentHandler handler` | 收集纸条的篮子 |
| `Metadata metadata` | 一本属性账本 |
| `ParseContext ctx` | 一个"上下文存包柜"，里面可以放 PDF 配置、OCR 配置、Parser 等 |

详细展开见：
- [[05 - 解析器 Parser 详解]]
- [[06 - 内容处理器 ContentHandler]]
- [[07 - 元数据 Metadata]]

## 4. 给文件名作为提示能更准

PDF 文件改了后缀叫 `.bin`，单看流也能检测对（魔数）。但**有些 Office 模糊格式（如老 .doc / RTF）加文件名提示**会显著提升准确率：

```java
metadata.set(TikaCoreProperties.RESOURCE_NAME_KEY, "report.pdf");
parser.parse(in, handler, metadata, ctx);
```

## 5. 大文件 / 内存友好

`BodyContentHandler(int writeLimit)` 内部用 `StringWriter`，全文要放内存。**要做流式**，传一个 `OutputStream` 或 `Writer`：

```java
// 边解析边写到磁盘
try (OutputStream os = Files.newOutputStream(Paths.get("out.txt"));
     Writer w = new OutputStreamWriter(os, StandardCharsets.UTF_8)) {

    ContentHandler handler = new BodyContentHandler(w);   // 流式
    parser.parse(in, handler, metadata, ctx);
}
```

或者直接写 SAX：见 [[06 - 内容处理器 ContentHandler#自定义 SAX Handler]]

## 6. 字符上限的几种姿势

```java
new BodyContentHandler();              // 默认 100_000 字符，超出抛 SAXException
new BodyContentHandler(-1);            // 不限制
new BodyContentHandler(5_000_000);     // 限 5M 字符
new BodyContentHandler(writer);        // 不限制，流式写出
```

> [!bug] `WriteOutContentHandler.WriteLimitReachedException`
> 这是**正常的"我说够了"信号**，不是真错误。如果你不希望它中断解析，要么放大 `writeLimit`，要么捕获它继续处理 Metadata（这种情况下 Metadata 可能不完整）。

## 7. 完整可运行示例

```java
package demo;

import org.apache.tika.metadata.Metadata;
import org.apache.tika.metadata.TikaCoreProperties;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.parser.Parser;
import org.apache.tika.sax.BodyContentHandler;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

public class TikaDemo {
    public static void main(String[] args) throws Exception {
        Path file = Path.of(args[0]);

        Parser parser = new AutoDetectParser();
        BodyContentHandler handler = new BodyContentHandler(10_000_000);
        Metadata meta = new Metadata();
        meta.set(TikaCoreProperties.RESOURCE_NAME_KEY, file.getFileName().toString());
        ParseContext ctx = new ParseContext();
        ctx.set(Parser.class, parser);

        try (InputStream in = Files.newInputStream(file)) {
            parser.parse(in, handler, meta, ctx);
        }

        System.out.println("=== METADATA ===");
        for (String name : meta.names()) {
            System.out.printf("%-40s : %s%n", name, meta.get(name));
        }
        System.out.println("\n=== TEXT (first 800 chars) ===");
        String text = handler.toString();
        System.out.println(text.substring(0, Math.min(800, text.length())));
    }
}
```

跑一下：

```bash
mvn -q compile exec:java -Dexec.mainClass=demo.TikaDemo -Dexec.args="some.pdf"
```

## 8. 速记口诀

> **"Auto / Body / Meta / Context, parse 一行通天下"**
>
> ```java
> new AutoDetectParser().parse(in, new BodyContentHandler(-1), new Metadata(), new ParseContext());
> ```

---

下一步：[[05 - 解析器 Parser 详解]] —— 把 Parser 这层吃透。
