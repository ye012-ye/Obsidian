---
title: Tika 在 Spring Boot 中集成
date: 2026-05-27
tags:
  - apache-tika
  - spring-boot
aliases:
  - Spring Boot Tika
  - Tika MultipartFile
---

# 16 · Spring Boot 集成

> [!info] 上一篇 / 下一篇
> ← [[15 - 性能调优与最佳实践]]　|　→ [[17 - 异常处理与故障排查]]

## 1. 依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.apache.tika</groupId>
        <artifactId>tika-core</artifactId>
        <version>3.2.3</version>
    </dependency>
    <dependency>
        <groupId>org.apache.tika</groupId>
        <artifactId>tika-parsers-standard-package</artifactId>
        <version>3.2.3</version>
    </dependency>
</dependencies>
```

## 2. 注册 Bean

```java
package com.acme.tika;

import org.apache.tika.config.TikaConfig;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.Parser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.InputStream;

@Configuration
public class TikaConfiguration {

    @Value("classpath:tika-config.xml")
    private Resource tikaConfigResource;

    @Bean
    public TikaConfig tikaConfig() throws Exception {
        try (InputStream in = tikaConfigResource.getInputStream()) {
            return new TikaConfig(in);
        }
    }

    @Bean
    public Parser tikaParser(TikaConfig cfg) {
        // AutoDetectParser 线程安全，整个 app 一份即可
        return new AutoDetectParser(cfg);
    }
}
```

> [!tip] 没有自定义配置就用默认
> 不需要 xml 时直接 `new AutoDetectParser()`，连 TikaConfig Bean 都省。

## 3. 通用 Service

```java
package com.acme.tika;

import org.apache.tika.metadata.Metadata;
import org.apache.tika.metadata.TikaCoreProperties;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.parser.Parser;
import org.apache.tika.sax.BodyContentHandler;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class ExtractionService {

    private final Parser parser;

    public ExtractionService(Parser parser) {
        this.parser = parser;
    }

    public ExtractResult extract(InputStream in, String fileName) {
        BodyContentHandler handler = new BodyContentHandler(10_000_000);
        Metadata meta = new Metadata();
        if (fileName != null) {
            meta.set(TikaCoreProperties.RESOURCE_NAME_KEY, fileName);
        }
        ParseContext ctx = new ParseContext();
        ctx.set(Parser.class, parser);

        try {
            parser.parse(in, handler, meta, ctx);
        } catch (Exception e) {
            throw new ExtractionFailed(fileName, e);
        }
        return new ExtractResult(handler.toString(), toMap(meta));
    }

    private Map<String, Object> toMap(Metadata m) {
        Map<String, Object> map = new LinkedHashMap<>();
        for (String name : m.names()) {
            String[] v = m.getValues(name);
            map.put(name, v.length == 1 ? v[0] : java.util.Arrays.asList(v));
        }
        return map;
    }

    public record ExtractResult(String text, Map<String, Object> metadata) {}
}

class ExtractionFailed extends RuntimeException {
    public ExtractionFailed(String name, Throwable cause) {
        super("Failed to extract: " + name, cause);
    }
}
```

## 4. REST Controller — 接收上传

```java
package com.acme.tika;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;

@RestController
@RequestMapping("/api/extract")
public class ExtractionController {

    private final ExtractionService svc;

    public ExtractionController(ExtractionService svc) { this.svc = svc; }

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<ExtractionService.ExtractResult> extract(
            @RequestParam("file") MultipartFile file) throws Exception {

        try (InputStream in = file.getInputStream()) {
            return ResponseEntity.ok(svc.extract(in, file.getOriginalFilename()));
        }
    }
}
```

`application.yml` 增大上传限制：

```yaml
spring:
  servlet:
    multipart:
      max-file-size: 200MB
      max-request-size: 200MB
```

## 5. 包一个 `RestController` 调外部 tika-server

如果你的部署是**业务 + 独立 tika-server**：

```java
@Bean
public RestClient tikaClient(@Value("${tika.server.url}") String url) {
    return RestClient.builder().baseUrl(url).build();
}

@Service
public class TikaRemoteService {
    private final RestClient client;
    public TikaRemoteService(RestClient client) { this.client = client; }

    public String extractText(byte[] bytes, String fileName) {
        return client.put()
            .uri("/tika")
            .header("Accept", "text/plain")
            .header("Content-Disposition", "attachment; filename=" + fileName)
            .body(bytes)
            .retrieve()
            .body(String.class);
    }
}
```

完整接口列表见 [[13 - tika-server REST API]]。

## 6. 异步 + 限流

把解析放后台线程，REST 立即返回 `202 Accepted`：

```java
@Bean
public ThreadPoolTaskExecutor tikaExecutor() {
    ThreadPoolTaskExecutor e = new ThreadPoolTaskExecutor();
    e.setCorePoolSize(4);
    e.setMaxPoolSize(8);
    e.setQueueCapacity(100);
    e.setThreadNamePrefix("tika-");
    e.initialize();
    return e;
}

@Service
public class AsyncExtractionService {
    private final ExtractionService svc;
    private final ThreadPoolTaskExecutor pool;
    private final ResultStore store;

    public String submit(MultipartFile file) throws IOException {
        String id = UUID.randomUUID().toString();
        byte[] bytes = file.getBytes();
        String name = file.getOriginalFilename();
        pool.submit(() -> {
            try (InputStream in = new ByteArrayInputStream(bytes)) {
                store.save(id, svc.extract(in, name));
            } catch (Exception e) {
                store.fail(id, e);
            }
        });
        return id;
    }
}
```

## 7. 全局异常处理

```java
@RestControllerAdvice
public class TikaErrorAdvice {

    @ExceptionHandler(EncryptedDocumentException.class)
    public ResponseEntity<?> encrypted(EncryptedDocumentException e) {
        return ResponseEntity.status(422).body(Map.of(
            "error", "encrypted",
            "msg", "文档加密，需要密码"));
    }

    @ExceptionHandler(TikaException.class)
    public ResponseEntity<?> tika(TikaException e) {
        return ResponseEntity.status(422).body(Map.of(
            "error", "parse_failed",
            "msg", e.getMessage()));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<?> tooLarge(MaxUploadSizeExceededException e) {
        return ResponseEntity.status(413).body(Map.of("error", "too_large"));
    }
}
```

详见 [[17 - 异常处理与故障排查]]。

## 8. 加 Actuator 指标

```java
@Service
public class MeteredExtractionService {
    private final ExtractionService delegate;
    private final Timer timer;

    public MeteredExtractionService(ExtractionService d, MeterRegistry reg) {
        this.delegate = d;
        this.timer = Timer.builder("tika.parse")
            .publishPercentiles(0.5, 0.9, 0.99)
            .register(reg);
    }

    public ExtractionService.ExtractResult extract(InputStream in, String name) {
        return timer.record(() -> delegate.extract(in, name));
    }
}
```

## 9. 测试

```java
@SpringBootTest
class ExtractionServiceTest {

    @Autowired
    ExtractionService svc;

    @Test
    void parses_pdf() throws Exception {
        try (InputStream in = new ClassPathResource("hello.pdf").getInputStream()) {
            var r = svc.extract(in, "hello.pdf");
            assertThat(r.text()).contains("Hello");
            assertThat(r.metadata().get("Content-Type"))
                .asString().contains("application/pdf");
        }
    }
}
```

## 10. 跟 [[14 - 各格式解析详解 PDF Office HTML]] 联动

需要 PDF OCR 时改造 service：

```java
PDFParserConfig pdf = new PDFParserConfig();
pdf.setOcrStrategy(PDFParserConfig.OCR_STRATEGY.AUTO);
ctx.set(PDFParserConfig.class, pdf);

TesseractOCRConfig ocr = new TesseractOCRConfig();
ocr.setLanguage("eng+chi_sim");
ctx.set(TesseractOCRConfig.class, ocr);
```

把这些放到 `@ConfigurationProperties` 里走 yaml 配，最优雅：

```yaml
tika:
  pdf:
    ocr-strategy: auto
    ocr-dpi: 300
  ocr:
    language: eng+chi_sim
    timeout-seconds: 120
```

---

下一步：[[17 - 异常处理与故障排查]] —— 翻译 Tika 抛的奇怪异常。
