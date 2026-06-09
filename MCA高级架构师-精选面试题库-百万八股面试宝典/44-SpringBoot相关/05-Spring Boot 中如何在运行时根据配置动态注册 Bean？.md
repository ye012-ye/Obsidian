Spring Boot 支持在运行过程中根据业务逻辑或配置自动注册 Bean，不通过静态注解创建，从而实现真正的动态扩展。以下是两种主流方式:

M

### 方式一：`ImportBeanDefinitionRegistrar`

实现该接口并在配置类上使用 `@Import` 即可介入 Spring 容器 Bean 定义阶段。其 `registerBeanDefinitions(...)` 方法中，开发者可基于配置或条件构造 `GenericBeanDefinition`，设置 beanClass、属性（如通过 Binder 绑定的配置）后，调用 `registry.registerBeanDefinition(...)` 注册。该接口执行时机优于 Bean 实例化，S 适合根据配置动态添加多个类似组件。

S

### 方式二：`BeanDefinitionRegistryPostProcessor`

作为 `BeanFactoryPostProcessor` 的子接口，它拥有 `postProcessBeanDefinitionRegistry(...)` 钩子，Spring 会在扫描并注册完注解形式的 BeanDefinition 后调用。开发者可通过 `EnvironmentAware` 或 `Binder` 获取外部配置数据，再使用 `BeanDefinitionBuilder` 或直接构建 `GenericBeanDefinition` 注册 Bean。B 这种方案可结合 YAML、Properties 等实现批量动态注册更多自定义 Bean。

B

### 两者对比

|  |  |  |  |
| --- | --- | --- | --- |
| **方式** | **注册时机** | **优势** | **典型场景** |
| ImportBeanDefinitionRegistrar | 注解扫描阶段 | 简洁，适合模块级动态注册 | 自定义 starter 自动装配 |
| BeanDefinitionRegistryPostProcessor | 完全 BeanDefinition 解析后 | 逻辑强可读性高，可引用配置 | 按配置生成多个实例 |
