Spring 在启动和扫描阶段会用多个组件协作解析 Bean 定义与类元数据，其中 `BeanDefinitionReader` 和 `MetadataReader` 各司职责，互相补充：

M

### 1. 定义与职责

- `BeanDefinitionReader`  
  是用于读取 Bean 定义的高层接口，职责是从 XML、Java 注解、Groovy 或其他来源加载和注册 `BeanDefinition`。例如：

- `XmlBeanDefinitionReader`：加载 XML 文件
- `AnnotatedBeanDefinitionReader`：处理注解标注类
- `ClassPathBeanDefinitionScanner`：扫描指定包路径中的组件

- `MetadataReader`  
  是一个底层 API，用于读取类字节码元数据（AnnotationMetadata、ClassMetadata、MethodMetadata 等），常通过 ASM 使用，并在类加载前读取注解和结构信息，从性能角度轻量高效，常用于扫描组件时过滤条件

S

### 2. 使用场景与流程

- `BeanDefinitionReader` 使用场景：

- Spring IoC 容器的初始化阶段，根据配置源构建 `BeanDefinition` 并注册到 `BeanDefinitionRegistry` 中，是解析 Bean 的直接入口。

- `MetadataReader` 使用场景：

- 被 `ClassPathBeanDefinitionScanner` 或 `ConfigurationClassParser` 等类使用，先扫描 classpath 并解析类元信息，如判断是否含 `@Component` 或条件注解，而无须实例化类，提升扫描性能。

B

**总结：**

- `BeanDefinitionReader` 聚焦于：从不同来源读取 Bean 定义、解析 Bean 配置信息并注入容器，作用于容器初始化；
- `MetadataReader` 专注于：以高性能方式浏览类的元数据（无需类加载），供扫描过滤和注解识别之用，作为容器构建过程的一部分工具。
