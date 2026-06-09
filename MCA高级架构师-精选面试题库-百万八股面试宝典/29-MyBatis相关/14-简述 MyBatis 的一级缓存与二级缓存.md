MyBatis 提供两级缓存机制，用于提升查询效率并减少数据库访问：M

#### ​一级缓存（本地缓存）

- **作用域**：每个 `SqlSession` 独立，默认开启，生命周期随会话结束或手动清除。
- **机制**：同一会话中，相同 SQL + 参数组合的查询，首次由数据库获取并缓存，再次查询直接从缓存中返回。
- **失效条件**：执行 `insert`、`update`、`delete`、调用 `clearCache()`、`commit()`、`rollback()` 或使用不同 `SqlSession` 时会清空缓存。

S

#### ​二级缓存（全局缓存）

- **作用域**：跨 `SqlSession`，在 mapper (`namespace`) 级别共享，需手动启用。
- **配置方式**：

1. 全局启用：在 `mybatis-config.xml` 设置 `<setting name="cacheEnabled" value="true"/>`。
2. Mapper 级开启：在 `<mapper>` 中添加 `<cache>` 标签。缓存类可指定序列化实现。

- **工作流程**：查询时优先查二级缓存，未命中再查一级缓存，最终访问数据库；提交或关闭 `SqlSession` 后，一级缓存内容刷入二级缓存。  
  B
- **特点与注意事项**：采用 LRU/FIFO 等驱逐策略；缓存对象需可序列化；当执行写操作后对应缓存失效；仅限单一 namespace，避免跨 namespace 冲突；在高并发或频繁更新环境下，可能导致缓存不一致或性能问题。
