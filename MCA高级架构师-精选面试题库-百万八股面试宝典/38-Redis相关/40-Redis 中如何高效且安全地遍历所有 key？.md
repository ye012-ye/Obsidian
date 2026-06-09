在生产环境中，应避免使用 `KEYS` 命令，因为它会阻塞服务器并造成性能问题。推荐使用增量遍历命令 `SCAN`（及其衍生命令：`SSCAN`、`HSCAN`、`ZSCAN`），既安全又高效。具体实现如下：

M

#### 1. 为什么选 SCAN

- `KEYS` 会一次性返回所有匹配 key，若数据量巨大（比如百万级），会阻塞 Redis，影响正常业务响应。
- 相比之下，`SCAN` 是游标迭代式命令，每次返回一小部分 key，可持续调用直到遍历结束。每次调用时间复杂度 O(1)O(1)O(1)，总体为 O(N)O(N)O(N)，不会一次性占用太多资源。

S

#### 2. 工作原理与特性

- 初始游标设为 `0`，每次 `SCAN cursor [MATCH pattern] [COUNT count]` 返回新游标和一批 key，直到游标再次为 `0` 表示遍历完成。
- SCAN 每次调用只在执行过程中短暂阻塞，但不会长时间影响 Redis 处理其他操作。

B

#### 3. Java/Jedis 实现示例

```java
String cursor = ScanParams.SCAN_POINTER_START;
ScanParams params = new ScanParams().match("*").count(100);
do {
    ScanResult<String> res = jedis.scan(cursor, params);
    List<String> keys = res.getResult();
    for (String key : keys) {
        // 处理 key，如统计、打日志等
    }
    cursor = res.getCursor();
} while (!cursor.equals(ScanParams.SCAN_POINTER_START));
```

重点是循环判断游标值为 `"0"` 或 reset 的初始游标。
