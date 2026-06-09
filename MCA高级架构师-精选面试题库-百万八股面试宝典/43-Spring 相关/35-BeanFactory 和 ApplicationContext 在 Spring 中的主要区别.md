#### 1. 接口关系与定位

- **BeanFactory** 是 Spring 的底层 IoC 容器接口，负责管理 Bean 的实例化与依赖注入。应用于轻量或延迟加载场景。
- **ApplicationContext** 继承自 BeanFactory，是一个功能更全面的“高级容器”，不仅管理 Bean，还提供更多企业级功能。

M

#### 2. Bean 初始化策略

- **BeanFactory** 默认采用延迟初始化，仅在 `getBean()` 调用时创建 Bean。适合资源受限环境。
- **ApplicationContext** 则使用急切加载，在容器启动时立即实例化所有单例 Bean，确保完整加载上下文。

S

#### 3. 企业功能支持

|  |  |  |
| --- | --- | --- |
| **功能模块** | **BeanFactory** | **ApplicationContext** |
| 国际化 (i18n) | 不支持 | ​支持 `MessageSource`  国际化消息解析 |
| 事件发布 | 不支持 | ​支持 `ApplicationEvent`  与 `ApplicationListener` |
| 注解 & AOP | 基本支持需手动配置 | 自动扫描注解，内建 AOP、后置处理器注入 |
| BeanPostProcessor 注册 | 需手动注册 | 开始阶段自动注册所有后置处理器 |
| 支持的 Scope 类型 | 单例 & 原型 | 支持所有：单例、多例、Request、Session 等 |

#### 4. 使用建议

- **BeanFactory**：适合简洁、小型程序或者内存敏感环境，如手持设备、嵌入式等。
- **ApplicationContext**：适合大多数 Spring 项目，尤其是 Web、企业级应用，因为它具备更完整的框架生态兼容性。

B

#### 5. 示例对比

```java
// 延迟加载示例：BeanFactory
BeanFactory bf = new XmlBeanFactory(new ClassPathResource("beans.xml"));
// Bean 不会立即创建，直到调用
MyBean b = bf.getBean("myBean", MyBean.class);

// 急切加载示例：ApplicationContext
ApplicationContext ac = new ClassPathXmlApplicationContext("beans.xml");
// 瞬间初始化所有单例 Bean
```
