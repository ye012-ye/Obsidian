---
title: 环境搭建与 Java Client 连接
tags:
  - Java
  - Elasticsearch
  - JavaClient
  - Maven
created: 2026-06-10
up: "[[00-MOC-Java-ES从0基础到大神]]"
description: 搭建本地 ES、添加 Java API Client 依赖、创建同步与异步客户端。
---

# 环境搭建与 Java Client 连接

> [!tip] 本章目标
> 你要能启动一个 ES，写一个 Java 客户端连上它，并完成最小健康检查。

## 推荐技术栈

| 组件 | 建议 |
|---|---|
| JDK | Java 17+，新项目可选 Java 21 |
| ES | 公司服务端是什么大版本，客户端就尽量同大版本 |
| Java 客户端 | `co.elastic.clients:elasticsearch-java` |
| Spring Boot | Boot 3.x 项目更适合搭配新客户端 |

> [!warning] 版本提醒
> 2026-06-10 查询到最新 Java API Client 是 `9.4.2`。教程示例用 9.x 风格；如果你的服务端是 ES 8.x，把依赖换成对应 8.x 版本。

## Maven 依赖

```xml
<properties>
    <elasticsearch.client.version>9.4.2</elasticsearch.client.version>
</properties>

<dependencies>
    <dependency>
        <groupId>co.elastic.clients</groupId>
        <artifactId>elasticsearch-java</artifactId>
        <version>${elasticsearch.client.version}</version>
    </dependency>
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
    </dependency>
</dependencies>
```

## 最小连接代码

```java
import co.elastic.clients.elasticsearch.ElasticsearchClient;
import co.elastic.clients.json.jackson.JacksonJsonpMapper;
import co.elastic.clients.transport.ElasticsearchTransport;
import co.elastic.clients.transport.rest5_client.Rest5ClientTransport;
import org.apache.hc.core5.http.HttpHost;
import org.elasticsearch.client.Rest5Client;

public class EsClientFactory {

    public static ElasticsearchClient create() {
        Rest5Client restClient = Rest5Client
                .builder(new HttpHost("http", "localhost", 9200))
                .build();
        ElasticsearchTransport transport = new Rest5ClientTransport(
                restClient,
                new JacksonJsonpMapper()
        );
        return new ElasticsearchClient(transport);
    }
}
```

> [!info] Client 分层
> `ElasticsearchClient` 负责强类型 API；`Transport` 负责 JSON 映射；底层 `Rest5Client` 负责 HTTP 连接池、请求发送、超时等传输细节。

## 最小健康检查

```java
ElasticsearchClient client = EsClientFactory.create();
var info = client.info();
System.out.println(info.clusterName());
System.out.println(info.version().number());
```

## 异步客户端

```java
import co.elastic.clients.elasticsearch.ElasticsearchAsyncClient;

ElasticsearchAsyncClient asyncClient = new ElasticsearchAsyncClient(transport);

asyncClient.info()
        .thenAccept(info -> System.out.println(info.version().number()))
        .exceptionally(ex -> {
            ex.printStackTrace();
            return null;
        });
```

> [!success] 怎么选同步还是异步
> 普通 Spring MVC 业务先用同步客户端，代码更直观。高并发网关、批处理、异步流水线再考虑异步客户端。

## 常见连接问题

| 现象 | 常见原因 | 处理 |
|---|---|---|
| `Connection refused` | ES 没启动或端口错 | 检查 `localhost:9200` |
| `401 Unauthorized` | 开启安全认证但没传账号/API key | 配置认证 |
| SSL 证书错误 | HTTPS 与证书不匹配 | 配 CA 证书或开发环境改 HTTP |
| 客户端方法不存在 | 客户端版本和示例版本不一致 | 对齐版本 |

> [!danger] 不要把密码写死在代码里
> 本地练习可以硬编码，真实项目必须放到环境变量、配置中心或密钥管理系统。

## 本章练习

1. 建一个 Maven 项目。
2. 引入 `elasticsearch-java`。
3. 写 `EsClientFactory`。
4. 调 `client.info()` 打印集群版本。
