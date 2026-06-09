SpringBoot中对配置文件加密采用 Jasypt进行加密，方式如下：M

1. **添加依赖与插件**  
   在 `pom.xml` 中引入 starter 与 Maven 加密插件：

```xml
<dependency>
  <groupId>com.github.ulisesbocchio</groupId>
  <artifactId>jasypt-spring-boot-starter</artifactId>
  <version>3.0.5</version>
</dependency>
<plugin>
  <groupId>com.github.ulisesbocchio</groupId>
  <artifactId>jasypt-maven-plugin</artifactId>
  <version>3.0.5</version>
</plugin>
```

Maven 插件用于在构建时或手动执行加密/解密，支持批量处理属性文件。

2. **加密流程**

- 在 `.properties` 或 `.yml` 中标记待加密值：  
  `spring.datasource.password=DEC(myPassword)`
- 使用 Maven 命令生成加密值：  
  `mvn jasypt:encrypt -Djasypt.encryptor.password=key`  
  或 `mvn jasypt:encrypt-value -Djasypt.encryptor.password=key -Djasypt.plugin.value=myPassword`
- 插件会替换为 `ENC(...)` 格式，方便自动解密

S

3. **运行时解密**

- 将密钥通过环境变量或 VM 参数注入：  
  `-Djasypt.encryptor.password=key`
- 启动后 Spring Boot 会自动解密属性，开发者通过 `@Value` 或 `Environment` 直接使用真实值，无需手动处理。

4. **高级配置**  
   可自定义 `@Bean jasyptStringEncryptor()`，指定算法（如 AES-256）、盐值生成策略或迭代次数等，以提升安全性。

B
