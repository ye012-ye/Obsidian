Dubbo 的 SPI（Service Provider Interface）机制是其插件化的基础架构，允许动态加载、替换或增强模块实现，提高系统灵活性与可扩展性。它解决了**组件耦合过高，难以替换或按需注入**的问题，适用于负载均衡、协议、注册中心、路由策略等多个扩展点。S

### 核心思想与机制

Dubbo 的 SPI 并非 JDK 原生机制，而是基于 `ExtensionLoader` 自有设计：

1. 接口上用 `@SPI("默认实现名")` 标注扩展点；
2. 在 `META-INF/dubbo/接口全限定名` 的配置文件中，用 `alias=实现类全名` 注册扩展；
3. 支持 AOP Wrapper、自动依赖注入（IoC）、按 `@Activate` 条件自动加载实现，并且提供 alias 和自动生成 adaptive 实例机制。

M

### 使用步骤（自定义示例）

1. **定义 SPI 接口**（例如自定义协议）：

```java
@SPI("cust")
public interface Protocol { … }
```

2. **实现类编写**：

```java
@Activate
public class CustProtocol implements Protocol { … }
```

3. **注册配置**：在 `resources/META-INF/dubbo/org.apache.dubbo.rpc.Protocol` 中添加：

```java
cust=com.example.CustProtocol
```

4. **启用方式**：B

- 使用 `ExtensionLoader.getExtensionLoader(Protocol.class).getExtension("cust")` 获取；
- 或在 Spring Boot 配置中设置 `dubbo.protocol.name=cust`。
