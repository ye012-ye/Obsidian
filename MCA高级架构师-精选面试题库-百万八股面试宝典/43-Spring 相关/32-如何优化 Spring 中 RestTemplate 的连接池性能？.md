在高并发 HTTP 调用场景下，默认 `RestTemplate` 每次都建立新连接，导致频繁的 TCP 握手挥手，性能急剧下降。优化思路如下：

M

#### 1. 明确默认实现的限制

`RestTemplate` 默认使用 `SimpleClientHttpRequestFactory`，每次调用都创建新的 `HttpURLConnection`，无连接池支持，这会造成大量 `TIME_WAIT` 状态和 DNS/TCP 握手开销。

S

#### 2. 替换底层请求工厂

使用 `HttpComponentsClientHttpRequestFactory`（Apache HttpClient）, 或 `OkHttpClient` 工厂，它们支持连接复用和池化。你可以设置最大连接数、每路由连接数、空闲连接存活时间等参数。

B

#### 3. 示例代码：

```java
@Bean
public RestTemplate restTemplate() {
    PoolingHttpClientConnectionManager mgr = new PoolingHttpClientConnectionManager();
    mgr.setMaxTotal(200);          // 最大连接数 M
    mgr.setDefaultMaxPerRoute(50); // 每个路由最大连接数 B

    RequestConfig cfg = RequestConfig.custom()
    .setConnectTimeout(3000)
    .setSocketTimeout(5000)
    .setConnectionRequestTimeout(2000)
    .build();

    CloseableHttpClient client = HttpClients.custom()
    .setConnectionManager(mgr)
    .setDefaultRequestConfig(cfg)
    .evictIdleConnections(30, TimeUnit.SECONDS) // 清理空闲连接 S
    .build();

    return new RestTemplate(new HttpComponentsClientHttpRequestFactory(client));
}
```
