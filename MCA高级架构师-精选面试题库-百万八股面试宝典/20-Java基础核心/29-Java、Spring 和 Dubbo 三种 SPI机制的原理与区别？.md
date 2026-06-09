SPI（Service Provider Interface）是 Java 提供的一种动态加载实现类的机制，旨在实现模块之间的解耦与扩展。它允许应用程序在运行时发现并使用第三方提供的具体实现，而无需在源代码中硬编码。

三者SPI原理及优缺点如下：M

**1. Java SPI （**`java.util.ServiceLoader`**）**

- **原理**：在 `META-INF/services/` 下放置接口全限定名的文件，内容为实现类全名。`ServiceLoader.load()` 会懒加载，通过 IO 读取并反射实例化接口实现。
- **优点**：JDK 内置，无第三方依赖，使用简单。
- **缺点**：一次性实例化所有实现，资源浪费；无法按名称获取，且实现定位信息少。S

**2. Spring SPI （**`SpringFactoriesLoader`**/**`spring.factories`**）**

- **原理**：集中在 `META-INF/spring.factories` 文件中以 `接口全名=实现类1,实现类2` 方式列出实现类。通过 `SpringFactoriesLoader.loadFactories()` 加载，通常会把类实例化后注入 Spring 容器。
- **优点**：支持按接口统一管理、多实现；IDEA 支持代码提示；借助 Spring 容器自动 IOC 注入。
- **缺点**：不支持按别名获取单一实现，依赖 Spring 环境，不适用于非 Spring 项目。

**3. Dubbo SPI (**`ExtensionLoader`**)**

- **原理**：接口需加 `@SPI` 注解，文件放在 `META-INF/dubbo/…`,内容为 `name=实现类全名`。`ExtensionLoader` 能按名称获取指定实现，支持懒加载、依赖注入（IOC）、AOP（通过 Wrapper）、自适应机制（Adaptive）、自动激活（Activate）等功能。
- **优点**：功能最丰富，可选择实现（别名）；支持延迟加载；提供 IOC、AOP、自适应及激活机制。
- **缺点**：只适合 Dubbo 框架使用，不是通用机制；机制复杂。 B

---

### 总结

|  |  |  |  |
| --- | --- | --- | --- |
| **​****特性** | **Java SPI** | **Spring SPI** | **Dubbo SPI** |
| 配置方式 | 多文件 (`META-INF/services`) | 单文件 (`spring.factories`) | 多目录 (`dubbo/`  , `services/`)，键=值方式 |
| 加载方式 | 按接口逐个实例化 | 实例化所有并注入 Spring | 延迟加载，按需实例化，可获取特定实现 |
| 获取方式 | 迭代所有实现 | 所有实现列表 | `getExtension("name")`  获取指定实现 |
| IOC/AOP 支持 | 无 | Spring 自动注入支持 | Dubbo 自带依赖注入和 AOP 支持 |
| 扩展机制 | 无 | 无 | 支持 Adaptive、自激活等功能 |
| 应用场景 | JDK 内置 SPI | Spring Boot 自动装配 | Dubbo Plugin 扩展机制 |
| 适用环境 | 通用，无依赖 | Spring 项目 | Dubbo 框架内部使用 |
