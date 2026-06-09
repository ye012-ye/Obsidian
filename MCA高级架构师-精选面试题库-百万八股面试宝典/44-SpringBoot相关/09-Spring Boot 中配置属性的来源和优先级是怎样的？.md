在 Spring Boot 中，配置属性来自多个来源，并按照预定义顺序加载，后加载的来源可以覆盖前者，从而实现灵活配置管理。整个加载过程可分为两部分：**PropertySource 加载顺序** 和 **外部文件查找顺序**。

M

### ① PropertySource 加载优先级（后者覆盖前者）

1. 默认属性（通过 `SpringApplication.setDefaultProperties` 设置）
2. `@PropertySource` 注解指定的配置
3. Config Data（如 `application.properties/yml` 等）
4. `RandomValuePropertySource`（如 `random.*`）
5. 操作系统环境变量
6. Java 系统属性（即 `-Dxxx=yyy`）
7. JNDI 属性
8. ServletContext 初始化参数
9. ServletConfig 初始化参数
10. `SPRING_APPLICATION_JSON` 内容
11. 命令行参数（如 `--server.port=9090`）
12. 测试相关属性（如 `@SpringBootTest` 中定义的配置等）

S

### ② 外部配置文件加载顺序

Spring Boot 支持在多个位置查找 `application.properties` 或 `.yml`，加载顺序如下（后者优先）：

1. 当前目录下的 `config/` 文件
2. 当前目录
3. classpath 下的 `config/`
4. classpath 根目录

同理，加载这些位置的配置时还会优先考虑 profile 特定文件：

- 在 jar 包内部：先 `application-{profile}.properties/yml`，再 `application.properties/yml`
- 在 jar 包外部：依次同样加载 profile 特定文件再默认文件

B

### ③ 总结逻辑

- **最底层**：默认属性 → `@PropertySource` → 内外部 application 文件 → `random.*`
- **中间层**：环境变量 → 系统属性 → JNDI → Servlet 参数 → JSON 配置
- **最高层**：命令行参数 → 测试用属性
- **文件加载上**：运行目录 > classpath，profile 配置优先于默认配置
