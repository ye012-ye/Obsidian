ShardingSphere 的数据加密功能（Encrypt Module）支持列级透明加密，通过配置加密规则来自动完成数据的加解密，用户无需显式处理细节。以下为完整流程与示例。

### 一、核心步骤概览

1. **定义数据源**：在配置文件中声明目标数据库连接。
2. **配置加密算法（Encryptor）**：选择 AES、MD5、RC4、SM3 或 SM4 等内置算法，或实现 `EncryptAlgorithm` 接口自定义加密机制。
3. **设置表列级加密规则**：指定表中哪些字段进行加密，定义逻辑列、密文列、辅助查询列、模糊查询列等映射关系。
4. **调用 ShardingSphereDataSource** 启用配置：通过 YAML 创建数据源后，所有 SQL 会自动根据加密规则处理数据。

### 二、YAML 配置示例

```yaml
dataSources:
  ds_encrypt:
    dataSourceClassName: com.zaxxer.hikari.HikariDataSource
    driverClassName: com.mysql.jdbc.Driver
    jdbcUrl: jdbc:mysql://localhost:3306/db_encrypt
    username: root
    password:

rules:
- !ENCRYPT
  tables:
    t_user:
      columns:
        username:
          cipher:
            name: username_cipher
            encryptorName: aes_encryptor
          assistedQuery:
            name: username_assisted
            encryptorName: md5_assisted
        pwd:
          cipher:
            name: pwd_cipher
            encryptorName: aes_encryptor
  encryptors:
    aes_encryptor:
      type: AES
      props:
        aes-key-value: 123456abc
    md5_assisted:
      type: MD5

props:
  sql.show: true
```

- `username` 字段配置了 `cipherColumn` 为 `username_cipher`，实际存储 AES 密文；
- `assistedQueryColumn` 用于加速查询场景，比如用 MD5 存储辅助索引值；
- 用户对表进行 `INSERT` 与 `SELECT pwd FROM t_user` 操作时，ShardingSphere 自动加密／解密，保证透明性。

### 三、加密机制原理

- **SQL 拦截与解析**：中间件捕获 SQL 后，查找逻辑列是否需加密处理。
- **写入阶段**：会使用加密算法将明文数据加密后写入 `cipherColumn`，并可能根据配置存储辅助索引或明文列。
- **查询阶段**：ShardingSphere 从 `cipherColumn` 读取密文，使用对应算法解密，然后返回给客户端；如果配置了辅助查询列，也可以支持基于辅助列的快速查找。
- 无论是写入还是读取，用户只需操作逻辑列，系统自动在幕后完成加密逻辑。

### 四、支持的加密算法类型

ShardingSphere 内置以下加密算法：

- **可逆加密**：AES、RC4、SM4（密码可解密）
- **不可逆加密**：MD5、SM3（只可用于一致性校验或辅助查询）
- **模糊查询加密**：CHAR\_DIGEST\_LIKE 等，用于支持 `LIKE` 查询的加密字段
- 用户也可以自定义实现 `EncryptAlgorithm` 接口扩展算法。
