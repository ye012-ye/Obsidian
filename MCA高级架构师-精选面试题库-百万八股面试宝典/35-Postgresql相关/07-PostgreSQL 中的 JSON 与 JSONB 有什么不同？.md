在 PostgreSQL 中，JSON 和 JSONB 都用来存储 JSON 数据，但它们的存储方式、性能表现及应用场景各有分工。

M

**1. 存储格式与解析机制**  
JSON 是以文本形式保存 JSON 原始字符串——包括空格、缩进、键顺序甚至重复键，插入速度较快，但每次读取都需重新解析；  
JSONB 是以二进制结构存储，解析后生成内部树结构，写入时需预处理，因此略慢，但读取时能直接访问特定字段，无需重新解析，提高查询效率；

**2. 性能与功能差异**

- **写入性能**：JSON 部分快于 JSONB；
- **读取与查询**：由于 JSONB 支持 GIN 索引，并可直接定位数据，所以检索性能远高于 JSON；
- **数据修改**：JSONB 提供如 `jsonb_set()`、`jsonb_insert()` 等操作可修改部分内容，JSON 则每次需整体替换；

S

**3. 数据内容保留与变动**

**4. 应用建议**

- **适合用 JSON 的场景**：

- 注重保留原始 JSON 结构（如日志、配置文档）；
- 预期只进行写操作，几乎不做查询；

- **适合用 JSONB 的场景**：

- 需频繁查询、过滤或复杂 JSON 操作（如电商属性、用户配置）；
- 需要对 JSON 内的数据建立索引、快速查询；
- 需对 JSON 内部结构进行部分更新；

B

**5. 示例对比：**

```plsql
-- JSONB 建立索引
CREATE INDEX ON profiles USING GIN (data jsonb_path_ops);

-- JSONB 查询：某字段值
SELECT data->>'status' FROM profiles WHERE data @> '{"status":"active"}';

-- JSON 写查询：每次都解析文本
SELECT data->>'status' FROM logs WHERE data->>'level' = 'ERROR';
```
