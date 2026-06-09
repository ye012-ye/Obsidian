---
title: tika-config.xml 配置详解
date: 2026-05-27
tags:
  - apache-tika
  - 配置
aliases:
  - TikaConfig
  - Tika 关闭某个 Parser
---

# 11 · tika-config.xml 配置

> [!info] 上一篇 / 下一篇
> ← [[10 - OCR 集成 Tesseract]]　|　→ [[12 - 嵌入式文档与递归解析]]

`tika-config.xml` 是 Tika 的**外部配置文件**，可以：

- ✅ 启用/禁用某些 Parser / Detector
- ✅ 给 Parser 传参（OCR 语言、PDF DPI …）
- ✅ 加自定义 Parser
- ✅ 限制 Parser 处理的 MIME 范围
- ✅ 改默认的 MIME 类型识别

## 1. 最小配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser"/>
    </parsers>
</properties>
```

加载：

```java
TikaConfig cfg = new TikaConfig(new File("tika-config.xml"));
Parser parser = new AutoDetectParser(cfg);

// CLI
// java -jar tika-app.jar --config=tika-config.xml --text in.pdf
```

## 2. 禁用某个 Parser

用 `parser-exclude` 把不要的踢掉：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser">
            <!-- 禁掉 ZIP 解析 -->
            <parser-exclude class="org.apache.tika.parser.pkg.PackageParser"/>
            <!-- 禁掉 OCR -->
            <parser-exclude class="org.apache.tika.parser.ocr.TesseractOCRParser"/>
        </parser>
    </parsers>
</properties>
```

## 3. 限定某个 Parser 只处理某些 MIME

让 PDFParser 只处理 PDF（默认就是，这只是演示语法）：

```xml
<parser class="org.apache.tika.parser.pdf.PDFParser">
    <mime>application/pdf</mime>
</parser>
```

## 4. 给 Parser 传参

```xml
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser"/>

        <parser class="org.apache.tika.parser.pdf.PDFParser">
            <params>
                <param name="extractInlineImages" type="bool">false</param>
                <param name="extractAnnotationText" type="bool">true</param>
                <param name="enableAutoSpace" type="bool">true</param>
                <param name="ocrStrategy" type="string">no_ocr</param>
                <param name="ocrDPI" type="int">300</param>
            </params>
        </parser>

        <parser class="org.apache.tika.parser.ocr.TesseractOCRParser">
            <params>
                <param name="language" type="string">eng+chi_sim</param>
                <param name="timeoutSeconds" type="int">120</param>
                <param name="minFileSizeToOcr" type="int">2000</param>
                <param name="maxFileSizeToOcr" type="int">20000000</param>
            </params>
        </parser>

        <parser class="org.apache.tika.parser.microsoft.OfficeParser">
            <params>
                <param name="extractMacros" type="bool">false</param>
                <param name="includeDeletedContent" type="bool">false</param>
                <param name="includeMoveFromContent" type="bool">false</param>
                <param name="useSAXDocxExtractor" type="bool">true</param>
            </params>
        </parser>
    </parsers>
</properties>
```

支持的 `type`：`string`, `int`, `long`, `bool`, `float`, `double`, `url`, `file`, `list`。

## 5. 加自定义 Parser

```xml
<parser class="org.apache.tika.parser.DefaultParser"/>
<parser class="com.acme.MyCustomParser">
    <mime>application/x-my-format</mime>
</parser>
```

参考 [[19 - 大神进阶 - 自定义解析器开发]]。

## 6. 服务端的"安全配置"

下面这套常用于**生产 tika-server**，关掉危险/重型解析器：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser">
            <!-- 关 ZIP 嵌套（防 zip bomb） -->
            <parser-exclude class="org.apache.tika.parser.pkg.PackageParser"/>
            <!-- 关执行类（exe/dll 等） -->
            <parser-exclude class="org.apache.tika.parser.executable.ExecutableParser"/>
            <!-- 关 SQLite -->
            <parser-exclude class="org.apache.tika.parser.sqlite3.SQLite3Parser"/>
            <!-- 关重型 OCR（按需开启） -->
            <parser-exclude class="org.apache.tika.parser.ocr.TesseractOCRParser"/>
        </parser>
    </parsers>

    <service-loader dynamic="true" loadErrorHandler="WARN"/>
    <encodingDetectors>
        <encodingDetector class="org.apache.tika.parser.txt.UniversalEncodingDetector"/>
    </encodingDetectors>
</properties>
```

## 7. 自定义 Detector

```xml
<properties>
    <detectors>
        <detector class="org.apache.tika.detect.DefaultDetector"/>
        <detector class="com.acme.MyMagicDetector"/>
    </detectors>
</properties>
```

## 8. 限制读取的字节数（防爆）

```xml
<properties>
    <autoDetectParserConfig>
        <writeLimit>10000000</writeLimit>             <!-- 文本最多 1000 万字符 -->
        <maxEmbeddedResources>100</maxEmbeddedResources>
    </autoDetectParserConfig>
</properties>
```

## 9. 在代码里"动态构造" TikaConfig

不一定要走文件：

```java
String xml = """
<?xml version="1.0"?>
<properties>
    <parsers>
        <parser class="org.apache.tika.parser.DefaultParser"/>
    </parsers>
</properties>
""";

TikaConfig cfg = new TikaConfig(new ByteArrayInputStream(xml.getBytes(UTF_8)));
```

## 10. Spring Boot 风格示例

```java
@Configuration
public class TikaConfiguration {

    @Value("classpath:tika-config.xml")
    private Resource configResource;

    @Bean
    public TikaConfig tikaConfig() throws Exception {
        try (InputStream in = configResource.getInputStream()) {
            return new TikaConfig(in);
        }
    }

    @Bean
    public Parser tikaParser(TikaConfig cfg) {
        return new AutoDetectParser(cfg);
    }
}
```

详见 [[16 - Spring Boot 集成]]。

## 11. 常见配置坑

> [!warning] 配置加载顺序
> Tika 找配置的顺序：
> 1. 构造 `TikaConfig(file)` 显式指定
> 2. `tika.config` 系统属性
> 3. classpath 根的 `tika-config.xml`
> 4. 默认（`DefaultParser` + `DefaultDetector`）
>
> 推荐**显式传 file 或 InputStream**，避免歧义。

> [!warning] `parser-exclude` 路径要写全
> `class` 必须是**全限定类名**。写错只会**静默忽略**。

> [!warning] 参数名拼错也会静默
> 比如 `extractAnnotation` 写成 `extractAnnotations` 不会报错。改完 **跑一遍验证**：
> ```bash
> java -jar tika-app.jar --config=tika-config.xml -v --text test.pdf
> ```

---

下一步：[[12 - 嵌入式文档与递归解析]] — 邮件附件、压缩包、Office 嵌图。
