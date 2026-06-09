#### 1、什么是Dubbo3

Apache Dubbo 是一款易用、高性能的 WEB 和 RPC 框架，同时为构建企业级微服务提供服务发现、流量治理、可观测、认证鉴权等能力、工具与最佳实践。

"Dubbo3 已在阿里巴巴内部微服务集群全面落地，成功取代运行多年的 HSF 框架。"

# 2、构建Dubbo3脚手架

## 2.1 框架依赖

- Maven

- SpringCloud 2.6.11

- Dubbo 3.1.8 + zookeeper 3.4.14

## 2.2 搭建Zookeeper

- 解压![](../assets/8d2489cbaf3cc0fb.png)

- 修改zk的配置文件进入conf，将文件zoo\_sample.cfg 改为zoo.cfg![](../assets/82aeeb5c9ef347f0.png)

- 测试zk启动zookeeper执行zookeeper根目录下，bin文件中的zkServer.cmd![](../assets/7e3d0d0811fc17d3.png)上面的CMD窗口不要关闭，这样zookeeper就是出于运行状态了

## 2.3 创建工程

### 2.3.1 创建父工程

mdb-dubbo-ann

父工程控制版本:

```plain
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>

        <artifactId>spring-boot-starter-parent</artifactId>

        <version>2.6.11</version>

        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <modules>
        <module>dubbo-consumer</module>

        <module>dubbo-provider</module>

        <module>dubbo-common</module>

    </modules>

    <groupId>com.msb</groupId>

    <artifactId>msb-dubbo-ann</artifactId>

    <version>0.0.1-SNAPSHOT</version>

    <name>msb-dubbo-ann</name>

    <packaging>pom</packaging>

    <description>Demo project for Spring Boot</description>

    <properties>
        <java.version>1.8</java.version>

        <dubbo-version>3.1.8</dubbo-version>

    </properties>

    <dependencies>
        <dependency>
            <groupId>org.projectlombok</groupId>

            <artifactId>lombok</artifactId>

        </dependency>

    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.apache.dubbo</groupId>

                <artifactId>dubbo-spring-boot-starter</artifactId>

                <version>${dubbo-version}</version>

            </dependency>

            <dependency>
                <groupId>org.apache.dubbo</groupId>

                <artifactId>dubbo-rpc-dubbo</artifactId>

                <version>${dubbo-version}</version>

            </dependency>

            <dependency>
                <groupId>org.apache.dubbo</groupId>

                <artifactId>dubbo-registry-zookeeper</artifactId>

                <version>${dubbo-version}</version>

            </dependency>

        </dependencies>

    </dependencyManagement>

</project>

```

### 2.3.2 创建提供者

dubbo-provider

引入依赖：

```plain
<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-spring-boot-starter</artifactId>

</dependency>

<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-rpc-dubbo</artifactId>

</dependency>

<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-registry-zookeeper</artifactId>

</dependency>

```

增加配置

```yaml
server:
  port: 8002
logging:
  config: classpath:logback.xml
dubbo:
  application:
    name: dubbo-provider
  protocol:
    name: dubbo
    #客户端链接20880就可以访问我们的dubbo
    port: 20883
  registry:
    address: zookeeper://127.0.0.1:2181
```

更改主类

```java
import org.apache.dubbo.config.spring.context.annotation.EnableDubbo;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ImportResource;
// 因为是自动装配也可以不加这个注解
@EnableDubbo(scanBasePackages = "com.msb.dubbo.provider.service")
@SpringBootApplication
public class DubboProviderApplication {
    public static void main(String[] args) {
        SpringApplication.run(DubboProviderApplication.class);
    }
}
```

接着增加通信端口

```java
public interface IUserService {
    User getUserById(Long id);
}
```

```java
@Data
@AllArgsConstructor
@Builder
public class User implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private String name;
    private int age;

}
```

增加实现类

```java
@DubboService// 定义一个dubbo服务
public class UserServiceImpl implements IUserService {
    @Override
    public User getUserById(Long id) {
        User user = User.builder().id(id)
                .age(12)
                .name("天涯")
                .build();
        return user;
    }
```

### 2.3.3 创建客户端

引入依赖

```plain
<!--这里是dubbo和SpringBoot桥梁的整合-->
<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-spring-boot-starter</artifactId>

</dependency>

<!--每一种协议都会对应的一个jar比方：dubbo、rest、tripe 三种协议-->
<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-rpc-dubbo</artifactId>

</dependency>

<!--注册中心可以是zk,nacos -->
<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-registry-zookeeper</artifactId>

</dependency>

```

更改配置

```yaml
server:
  port: 8001
logging:
  config: classpath:logback.xml
dubbo:
  application:
    name: dubbo-consumer
  registry:
    address: zookeeper://127.0.0.1:2181
```

更改主类

```java
@EnableDubbo
@SpringBootApplication
public class DubboConsumeApplication {
    public static void main(String[] args) {
        SpringApplication.run(DubboConsumeApplication.class);
    }
}
```

增加调用接口

```java
public interface IUserService {
    User getUserById(Long id);
}
```

```java
@Data
@AllArgsConstructor
@Builder
public class User implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private String name;
    private int age;

}
```

增加业务调用处理

```java
@RestController
public class OrderController {
    @Autowired
    private OrderService orderService;

    @RequestMapping("/createOrder/{userId}")
    public String createOrder(@PathVariable("userId") Long userId){
        return orderService.createOrder(userId);
    }
}
```

```java
@Slf4j
@Service
public class OrderService {
    // 引用对应的dubbo服务
    @DubboReference
    private IUserService iUserService;
    public String createOrder(Long userId){
        User user = iUserService.getUserById(userId);
        log.info("用户用户信息：{}",user);
        return "创建订单成功";
    }
}
```

### 2.3.4 测试

<http://localhost:8001/createOrder/232>

![](../assets/7915da35d998e073.png)

### 2.3.5 重构创建公共模块

dubbo-common 存放IUserService 和User

提供端和消费端

```plain
<dependency>
    <groupId>com.msb</groupId>

    <artifactId>dubbo-common</artifactId>

    <version>0.0.1-SNAPSHOT</version>

</dependency>

```

### 2.3.6 测试

<http://localhost:8001/createOrder/232>

![](../assets/0a804dad55615efe.png)

## 2.4 开启rest协议

如果我们的服务希望既要支持dubbo协议调用，也要能支持http调用，所以，要么仍然保留SpringMVC那一套，如果不想保留那一套，就可以开启 dubbo中的rest协议。

### 2.4.1 增加依赖

```plain
<dependency>
    <groupId>org.apache.dubbo</groupId>

    <artifactId>dubbo-rpc-rest</artifactId>

</dependency>

```

### 2.4.2 更改配置

```yaml
dubbo:
  application:
    name: dubbo-provider
  # 这里的协议加了s,所以可以设置多个通信协议
  protocols:
    p1:
      name: dubbo
      #客户端链接20883就可以访问我们的dubbo
      port: 20883
    p2:
      name: rest
      #客户端链接20884就可以访问我们的rest
      port: 20884
```

### 2.4.3 更改对应代码服务

```java
@DubboService// 定义一个dubbo服务
@Path("/user")
public class UserServiceImpl implements IUserService {
    @GET
    @Path("/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    @Override
    public User getUserById(@PathParam("userId") Long userId) {
        User user = User.builder().id(userId)
                .age(12)
                .name("天涯")
                .build();
        return user;
    }

}
```

### 2.4.4 测试

在消费端增加RestTemplate

```java
@EnableDubbo
@SpringBootApplication
public class DubboConsumeApplication {

    @Bean
    public RestTemplate restTemplate(){
        return new RestTemplate();
    }
    public static void main(String[] args) {
        SpringApplication.run(DubboConsumeApplication.class);
    }
}
```

```java
@Slf4j
@Service
public class OrderService {
    @DubboReference
    private IUserService iUserService;

    @Autowired
    RestTemplate restTemplate;
    public String createOrder(Long userId){
        User user = restTemplate.getForObject("http://localhost:20884/user/232",User.class);
        log.info("用户用户信息：{}",user);
        return "创建订单成功";
    }
}
```

<http://localhost:8001/createOrder/232>

![](../assets/58216c09f14cd7b7.png)

### 2.4.5 使用接口调用Rest

将rest协议放到common中

```plain
 <dependency>
            <groupId>org.apache.dubbo</groupId>

            <artifactId>dubbo-rpc-rest</artifactId>

        </dependency>

```

修改IUserService

```java
@Path("/user")
public interface IUserService {
    @GET
    @Path("/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    User getUserById(@PathParam("userId") Long id);
}
```

修改consume里面内容

```java
@Slf4j
@Service
public class OrderService {
    // 指定写协议
    @DubboReference(protocol = "rest")
    private IUserService iUserService;

    @Autowired
    RestTemplate restTemplate;
    public String createOrder(Long userId){
        User user = iUserService.getUserById(userId);
        log.info("用户用户信息：{}",user);
        return "创建订单成功";
    }
}
```

如果我们不能确定是否是走的http，我们可以DispatcherServlet#service 里面打个端点，看是否进入

![](../assets/8d34d45a5733dc9f.png)

# 3、Dubbo3 架构

![](../assets/198c47fb96ec8a31.png)

# 4、服务注册

## 4.1 Zookeeper注册数据基本结构

我们可以用zkCli.cmd来链接服务，查看对应的节点， 我们可以想象成一个一个的文件夹，

![](../assets/615cbfeebf8effb5.png)

使用ZooInspector来查看对应的节点

=![](../assets/4e6e0b024d9480c7.png)

## 4.2 接口级注册

![](../assets/5fcece663c53705f.png)

在这个过程中：

- 每个 Provider 通过特定的 key 向注册中心注册本机可访问地址；

- 注册中心通过这个 key 对 provider 实例地址进行聚合；

- Consumer 通过同样的 key 从注册中心订阅，以便及时收到聚合后的地址列表；

### 4.2.1 数据结构

![](../assets/ee6b808fd6756455.png)

### 4.1.2 接口易用性代价

![](../assets/6b16132b182eb9a4.png)

一个事物总是有其两面性，Dubbo2 地址模型带来易用性和强大功能的同时，也给整个架构的水平可扩展性带来了一些限制。这个问题在普通规模的微服务集群下是完全感知不到的，而随着集群规模的增长，当整个集群内应用、机器达到一定数量时，整个集群内的各个组件才开始遇到规模瓶颈。在总结包括阿里巴巴、工商银行等多个典型的用户在生产环境特点后，我们总结出以下两点突出问题（如图中红色所示）：

- 首先，注册中心集群容量达到上限阈值。由于所有的 URL 地址数据都被发送到注册中心，注册中心的存储容量达到上限，推送效率也随之下降。

- 而在消费端这一侧，Dubbo2 框架常驻内存已超 40%，每次地址推送带来的 cpu 等资源消耗率也非常高，影响正常的业务调用。

为什么会出现这个问题？我们以一个具体 provider 示例进行展开，来尝试说明为何应用在接口级地址模型下容易遇到容量问题。 青蓝色部分，假设这里有一个普通的 Dubbo Provider 应用，该应用内部定义有 10 个 RPC Service，应用被部署在 100 个机器实例上。这个应用在集群中产生的数据量将会是 “Service 数 \* 机器实例数”，也就是 10 \* 100 = 1000 条。数据被从两个维度放大：

- 从地址角度。100 条唯一的实例地址，被放大 10 倍

- 从服务角度。10 条唯一的服务元数据，被放大 100 倍

## 4.3 应用级注册

![](../assets/8c933f82847d38a0.png)

那这样 1个服务有10个服务接口 100个实例对应数据应该

mapping里面有 10条 services 里面就100 条 总共是110条

这里元数据可以放到元数据中心（可以和注册中心一样），也可以放到本地，消费者获取需要发送rpc调用

默认发送本地 ，对应配置

![](../assets/b94b1049e4cc0d36.png)

## 4.4 Provider和Consumer双版本支持参数讲解

**Provicer提供方**

dubbo.application.register-mode

|  |  |
| --- | --- |
| 参数 | 参数含义 |
| interface | 只有接口级注册 |
| instance | 只有应用级注册 |
| all（默认） | 接口级注册和应用级注册并存 |

![](../assets/fb2ddc7249470469.png)

**Consumer消费方**

dubbo.application.service-discovery.migration:FORCE\_INTERFACE

|  |  |
| --- | --- |
| 参数 | 参数含义 |
| FORCE\_INTERFACE | 只消费接口级地址，如无地址则报错，单订阅2.x地址 |
| APPLICATION\_FIRST(默认) | 智能决策接口级/应用级地址，双订阅 |
| FORCE\_APPLICATION | 只消费应用级地址，如无地址则报错，单订阅3.x地址 |

![](../assets/83f43310b2ae1d40.png)

## 4.5 为什么Dubbo3支持双版本注册

为了方便迁移， Dubbo3.0之前都是接口级别注册，Dubbo3之后都是应用级注册

# 5、服务注册源码分析

## 5.1 服务启动

找入口 是@EnableDubbo

![](../assets/a73bb8f548800331.png)

### 5.1.1 注册**DubboDeployApplicationListener**

这里监听器是监听Spring容器启动之后，我们再进行服务注册，不符订阅，应用注册，启动本地服务

![](../assets/47e9b772f294b3a3.png)

![](../assets/76ce340f54c4a44f.png)

![](../assets/9b9edcf0fbc27512.png)

![](../assets/4b55a238ad481177.png)

![](../assets/b841312dbd16f588.png)

![](../assets/2ffb1c073c535674.png)

### 5.1.2 扫描我们@DubboService 注册BeanDefinition

![](../assets/2e2a62299ba43024.png)

![](../assets/606e717c097f647b.png)

DubboComponentScanRegistrar 执行的时候会调用registerBeanDefinitions

![](../assets/b97224cbc5a3765a.png)

注册后置处理器ServiceAnnotationPostProcessor

![](../assets/981c09b263dc56e3.png)

![](../assets/17bbb0c8222e535c.png)

ServiceAnnotationPostProcessor 实现**BeanDefinitionRegistryPostProcessor**则进行BeanDefintion的注册

![](../assets/8684db4b2eb295af.png)

![](../assets/0e76f09acaa902e8.png)

注册userServiceImpl

![](../assets/7e49e4d3da6c6bb4.png)

注册ServieBean的BeanDefinition

![](../assets/fba8625c6a65b957.png)

### 5.1.3 加载配置文件

![](../assets/34e588681478ad37.png)

![](../assets/6bafc6a3598682c3.png)

![](../assets/158d49de5daf46cb.png)

![](../assets/514a1512bef82e38.png)

配置的加载

![](../assets/35c4fcdb1c71c97c.png)

![](../assets/b3d40d862b4a8d66.png)

## 5.2 服务导出

#### 面试题：Dubbo3是什么时候进行服务导出的？

Dubbo3通过DubboDeployApplicationListener监听Spring的启动，当Spring启动会发送ContextRefreshedEvent事件，**DubboDeployApplicationListener**监听这个事件进行服务导出，会把我们服务注册到注册中心，并且启动本地服务。

**问题： 服务导出 ：获取服务配置 + 服务注册（服务） + 启动服务（Netty/Tomcat），那先注册再启动，还是先启动再注册？**

先启动再注册，如果先注册再启动，那么注册完还没有启动的时候，别的服务就调用进来这就会出现调用失败

这里注意有接口级的注册和应用的注册

### 5.2.1 入口分析

我们通过**DubboDeployApplicationListener**

![](../assets/43161978bb091aa2.png)

![](../assets/d9586420b197aa72.png)

![](../assets/a01393e100876dde.png)

如下图这里就是核心内容

![](../assets/44da17aa0ac17f9e.png)

### 5.2.2 接口级注册

![](../assets/c440f547cc88a041.png)

#### 5.2.2.1 判断注册方式

exportServices是进行接口级注册，由于他的调用链路比较长我们直接来到 ServiceConfig#doExportUrls

通过配置的模式获取对应注册地址

![](../assets/3c250f62f1c19d91.png)

![](../assets/a8d726cbce590a5a.png)

![](../assets/1f080e5f76cfa3fb.png)

![](../assets/b5a4571e7d8194b6.png)

可以看到这里简化的配置比较容易理解了

- 双注册模式配置查询 对应参数为dubbo.application.register-mode ，默认值为all

- 如果用户配置了接口注册模式配置则只走接口级配置 这里默认值为interface

- 满足应用级注册就添加一个应用级注册的地址

- 满足接口级注册配置就添加一个接口级注册地址

这个方法是根据服务注册模式来判断使用接口级注册地址还是应用级注册地址分别如下所示： 配置信息： dubbo.application.register-mode 配置值：

- interface

- 接口级注册

- instance

- 应用级注册

- all

- 接口级别和应用级都注册

最终的注册地址配置如下： 接口级注册地址

```java
registry://127.0.0.1:2181/org.apache.dubbo.registry.RegistryService?application=dubbo-demo-api-provider&dubbo=2.0.2&pid=9008&registry=zookeeper&release=3.0.8&timestamp=1653703292768
```

应用级注册地址：

```java
service-discovery-registry://127.0.0.1:2181/org.apache.dubbo.registry.RegistryService?application=dubbo-demo-api-provider&dubbo=2.0.2&pid=10275&registry=zookeeper&release=3.0.8&timestamp=1653704425920
```

前面说了这个注册服务的配置地址会由Dubbo内部进行判断如果判断是all的话会自动将一个配置的注册地址转变为两个一个是传统的接口级注册，一个是应用级注册使用的配置地址

#### 5.2.2.2 生成invoke

![](../assets/c72294552f3afbdd.png)

我们来看key1:获取对应的invoke

![](../assets/5e9b5548c909b858.png)

然后我们再看注册中心，注册服务数据的源码 如果想要查看源码细节可以在RegistryProtocol类型的export(final Invoker originInvoker) 方法的如下代码位置打断点：

RegistryProtocol的export方法的注册中心注册数据代码如下:

![](../assets/ddc527d7d983e773.png)

1、暴露本地服务，就是提供给调用方一个调用的接口服务，这个我们后面来说

2、获取注册Registry ，这里如果是接口级注册则是ZookeeperRegistry，如果应用级注册：ServiceDiscoveryRegistry

3、我们看一下registry

#### **5.2.2.3 接口级注册**

我们再ZookeeperRegistry#doRegistry打上端点

![](../assets/ff382ae645bf50c0.png)

![](../assets/b319f37540d6ba40.png)

堆栈信息中我们可以看到调用它的方法是

![](../assets/8ac6a04c5920aefd.png)

![](../assets/63c2d9e610475d7f.png)

#### **5.2.2.4 应用级注册**：**将服务提供者数据转换到本地内存的元数据信息中**

![](../assets/1c32cd8809562b40.png)

![](../assets/e2cba9222d01ba4c.png)

#### 5.2.2.5 映射数据注册（应用）

![](../assets/d6564acd9d9e29e5.png)

![](../assets/0acdceb9e2245fb0.png)

![](../assets/d86ae4a6f8993699.png)

### 5.2.3 应用级注册

![](../assets/d46590c436b29f0b.png)

#### 5.2.3.1 应用元数据信息注册

![](../assets/50258238dbc9ced3.png)

![](../assets/7f8d0df5415f058e.png)

![](../assets/fb1425254ff6846e.png)

#### 5.2.3.2 实例信息

![](../assets/50258238dbc9ced3.png)

![](../assets/9d82ef3ec34c7ed0.png)

这里最终会调用到ZookeeperServiceDiscovery#doRegister

![](../assets/2e5684563e9dd046.png)

![](../assets/1b64ff9df10c16b0.png)

![](../assets/736367077d29e666.png)

![](../assets/ba0932272ec2b4c4.png)

# 6、本地服务暴露

那我们注意点如果是dubbo我们应该用netty绑定一个端口

![](../assets/303bf113d1734636.png)

![](../assets/c6327220a0bc82c8.png)

![](../assets/e420e104d7530a94.png)

![](../assets/7aa8240546da77fc.png)

![](../assets/e47026139b73483a.png)

![](../assets/338e18cd2ef4d74c.png)

这里最终会调用到 NettyServer#doOpen

![](../assets/64444c7597ab89d2.png)

# 7、Consumer的订阅服务

![](../assets/152a74abe80269f1.png)

## 7.1 订阅入口

来到关键入口类DefaultModuleDeployer#startSync 方法

![](../assets/16e9acf43b2680ce.png)

![](../assets/2f5869d0f82da3d7.png)

![](../assets/63444ddb9469c8fb.png)

![](../assets/adba2b0599eeaa43.png)

![](../assets/1d1cb42db2bbec6d.png)

这里分两点：1、是创建一个远程调用 invoke，2、创建代理类

我们先看第1点

![](../assets/8cbb2590fa187588.png)

![](../assets/c6cd94ff844a31f9.png)

![](../assets/0a86223c7abfc808.png)

![](../assets/b1b603a9767f7cab.png)

![](../assets/d2249b651f5d861e.png)

![](../assets/985b4d7029ea6068.png)

![](../assets/cc3005ff8fd60270.png)

## 7.2 接口级订阅

这里我们进入选择应用级订阅、接口级订阅、应用和接口级订阅， 我们进入应用和接口级订阅

![](../assets/8f737e439aacc1db.png)

![](../assets/ec56e2ac0d4618f4.png)

首先进入接口级订阅：

![](../assets/5563ef32026100ae.png)

![](../assets/bd8b70bafb99ffd7.png)

![](../assets/f795e772c7de379a.png)

最终会到 FailbackRegistry#subscribe

![](../assets/2eb80cef9c477e25.png)

![](../assets/1e2f9f1e4ecc2cdc.png)

![](../assets/2ba4412784e1cd76.png)

![](../assets/9b0fecdc9d563b9d.png)

上面是进行目录 创建，有则忽略，没有则创建， 让后给子节点增加监听器

最后将数据urls放到缓存

![](../assets/63824d64145df65c.png)

![](../assets/63a4a94e621bf805.png)

![](../assets/4faf8748c1428bf1.png)

![](../assets/c1b5d63ab6dfe1b8.png)

## 7.3 应用级订阅

这里我们进入选择应用级订阅、接口级订阅、应用和接口级订阅， 我们进入应用和接口级订阅

![](../assets/fb830615e1a6a0b5.png)

![](../assets/b30def4fcb6a74d5.png)

应用级订阅

![](../assets/1052b30e5c547662.png)

![](../assets/6e27417cff293527.png)

最终会调用到ServiceDiscoveryRegistry#doSubscribe

这里面设计到两个关键点、

![](../assets/17b3469043272fa2.png)

1、获取接口对应的应用名称

![](../assets/9d44f9ebb5b290d1.png)

![](../assets/2461622deef62126.png)

![](../assets/3b518987b73baec3.png)

![](../assets/9db80444deeaa363.png)

2、subscribedServices为接口所对应的应用名，接下来就会取获取该应用的所有实例

![](../assets/d1e99deb29f1ec61.png)

获取对应实例的元数据信息

循环发送事件ServiceInstancesChangedEvent，ServiceInstancesChangedListener#onEvent获取对应事件来获取对应的元数据信息

![](../assets/5302d0ae560fd827.png)

![](../assets/588a7babfa7359c8.png)

这里我们重点分析一下从远端获取数据

![](../assets/699e372f5cc06a8b.png)

![](../assets/6a27365b88012ede.png)

## 7.4 智能选择 接口级还是应用级

![](../assets/958e395797de013b.png)

![](../assets/ebe8c34b2068d9d1.png)

![](../assets/cd3207afe5712e90.png)

如果应用级注册为空，接口级注册不为空，则是使用接口级注册

如果接口级注册为空，应用级注册不为空，则是使用应用级注册

如果接口级和应用级都不为空，则用应用级

## 7.5 创建代理类

![](../assets/b043f55a5df54dd8.png)

最终回到用到JavassistProxyFactory

![](../assets/41fa0179cab32490.png)

## 7.6 @DubboReference标注对象的引入

![](../assets/1ee22d397190a90b.png)

![](../assets/e263d4f9821737b2.png)

我们看一下ReferenceAnnotationBeanPostProcessor的继承关系

![](../assets/5c69023bf5c7aeea.png)

它继承BeanFactoryPostProcessor,所以他一定为实现postProcessBeanFactory

![](../assets/30b74a50a6dff2b7.png)

![](../assets/c093965e79316296.png)

![](../assets/b3e537f4fd72b63e.png)

后面会将@DubboReference标注类对应的BeanDefinition进行实例化，我们看一下对应class类ReferenceBean

![](../assets/8e8bc95ab4128950.png)

问题：我们如果想往IOC容器中注入一个对象应该怎样处理

使用@Bean进行方法的标注 或者实现接口FactoryBean

所以此时应该关注ReferenceBean#getObject

![](../assets/b9d1ea9371a3554f.png)

![](../assets/58aa0c745f25aefe.png)

所以在服务调用的时候才创建代理类进行调用

![](../assets/456853fbd105dcd8.png)

# 8、Dubbo协议 服务调用

## 8.1 服务端 启动过程深入分析

![](../assets/c103d999cde15324.png)

我们查看一下服务启动的过程

ProtocolFilterWrapper.export

![](../assets/b1e3f8ee68e4b097.png)

![](../assets/0162d0fce0c33746.png)

好我们进入DubboProtocol.export

![](../assets/70620e6cb42aaf8f.png)

创建服务

![](../assets/a8c3ef63543beca5.png)

![](../assets/750de7c28808077b.png)

**分析我们的Handler**![](../assets/b1443ced6bfa1378.png)

![](../assets/348e428de6e3b7f8.png)

我们接着返回刚才位置

![](../assets/42e10ef950a3a48a.png)

![](../assets/7da629cb3a42e6ea.png)

![](../assets/71c5b2f85bab6a35.png)

![](../assets/891396ac1cff0c2c.png)

![](../assets/db1f974e0ee7c95c.png)

下面的super方法里面会创建服务，ChannelHandlers.wrap会对hander进一步包装

![](../assets/a5a46a5a6711ec8d.png)

1、我们进入ChannelHandlers.wrap

![](../assets/5cd425c4c25431eb.png)

![](../assets/8e286133df9960f0.png)

MultiMessageHandler--->HeartbeatHandler---->AllChannelHandler -> DecodeHandler -> HeaderExchangeHandler -> ExchangeHandlerAdapter

我看看一下super创建服务

![](../assets/b28a23c6cc86462a.png)

![](../assets/64f4b8766c87a1cd.png)

![](../assets/08237962f2bcae11.png)

NettyServerhandler -> NettyServer -> MultiMessageHandler--->HeartbeatHandler---->AllChannelHandler -> DecodeHandler -> HeaderExchangeHandler -> ExchangeHandlerAdapter

## 8.2 服务端调用过程

![](../assets/431d0bef3fc898d9.png)

![](../assets/e283a1c019c7b0dd.png)

![](../assets/095593237cffe20a.png)

我们知道请求过来通过Netty服务一定是Handler的处理,下面就是整个过程

NettyServerHandler -> NettyServer -> MultiMessageHandler--->HeartbeatHandler---->AllChannelHandler -> DecodeHandler -> HeaderExchangeHandler -> ExchangeHandlerAdapter

**NettyServerHandler**

![](../assets/7c2662e017f57316.png)

MultiMessageHandler

![](../assets/8b7cf3a96006dcf4.png)

HeartbeatHandler

![](../assets/78518c72a2275433.png)

**AllChannelHandler**

<https://cn.dubbo.apache.org/zh-cn/overview/mannual/java-sdk/advanced-features-and-usage/performance/threading-model/provider/>

![](../assets/5a9d445f8c851257.png)

**DecodeHandler**

![](../assets/e55696f3c118fe00.png)

**HeaderExchangeHandler**

![](../assets/34592e60908fb786.png)

**ExchangeHandlerAdapter**

![](../assets/558ff317e269b612.png)  
这里是调用我们的目标invoker，但是这里目标invoker被filter给包装了，所以先要调用filter

![](../assets/8b0faf41ce8d1c97.png)

我们自定义过滤器就会在这里起作用

调用完毕过滤器就会调用到AbstractProxyInvoker#invoke

![](../assets/6c252993d9101652.png)

![](../assets/e2298e716e07e679.png)

## 8.3 客户端调用

![](../assets/e9da198e9a1b381f.png)

会调用JavassistProxyFactory#getProxy获取代理类

![](../assets/adb1882b54402841.png)

调用的时候一定会调用到InvokerInvocationHandler.invoker的方法

![](../assets/89f256a3fe01940c.png)

![](../assets/39d87af0b3fedc10.png)

![](../assets/ad6a1ce8a3f7fd73.png)

调用过程会有容错负载均衡FailoverClusterInvoker#doInvoke

![](../assets/f6d7dc9f511f344e.png)![](../assets/a35ea093fd360799.png)

我们可以简单看一下负载均衡

![](../assets/a55e94b72a962944.png)

![](../assets/5eace0f0ea409c15.png)

HeaderExchangeChannel#request发送请求

![](../assets/769b378da1fddb0c.png)

HeaderExchangeHandler#received处理返回数据

![](../assets/788db950594c6742.png)

![](../assets/6e81860a79f03ba7.png)

# 9、Triple协议

## 9.1 背景

```plain
在Dubbo2.7中，默认的是Dubbo协议，因为Dubbo协议相比较于Http1.1而言，Dubbo协议性能上是要更好的。
```

```plain
但是Dubbo协议自己的缺点就是不通用，假如现在通过Dubbo协议提供了一个服务，那如果想要调用该服务就必须要求服务消费者也要支持Dubbo协议。
```

```plain
而随着企业的发展，往往可能会出现公司内部使用多种技术栈，可能这个部门使用Dubbo，另外一个部门使用Spring Cloud，另外一个部门使用gRPC，那此时部门之间要想相互调用服务就比较复杂了，所以需要一个通用的、性能也好的协议，这就是Triple协议。
```

## 9.2 Triple协议介绍

Triple 是 Dubbo3 提出的基于 HTTP2 的开放协议，旨在解决 Dubbo2 私有协议带来的互通性问题。另外，Google公司开发的gRPC，也基于的HTTP2，目前gRPC是云原生事实上协议标准，包括k8s/etcd等都支持gRPC协议。

## 9.3 HTTP1 和HTTP2进行对比

### 9.3.1 HTTP1

![](../assets/ebf19498f5563cf0.png)

```http
POST /getName HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 27

username=john&password=1234
```

我们会发现我们除了username=john&password=1234 数据之外，其他的内容都是额外信息，并且这些额外信息量很大。

### 9.3.2 HTTP2

![](../assets/0576de6892a3a03d.png)

1. 帧长度，用三个字节来存一个数字，这个数字表示当前帧的实际传输的数据的大小，3个字节表示的最大数字是2的24次方（16M），所以一个帧最大为9字节+16M。

2. 帧类型，占一个字节，可以分为数据帧和控制帧

1. DATA：用于传输请求和响应中的数据，包含有效载荷（payload）。

2. HEADERS：用于传输HTTP头部信息，包含有效载荷（payload）。

3. PRIORITY：用于指定数据流的优先级，包含与数据流相关的信息。

4. RST\_STREAM：用于指示数据流的中止，并通知原因。

5. SETTINGS：用于传输HTTP/2连接的配置参数。

6. PUSH\_PROMISE：用于服务端推送资源，包含预期的请求头和有效载荷。

7. PING：用于检测HTTP/2连接的可用性和延迟时间。

3. 标志位，占一个字节，可以用来表示当前帧是整个请求里的最后一帧，方便服务端解析、

4. 流标识符，占4个字节，在Java中也就是一个int，不过最高位保留不用，表示Stream ID，这也是HTTP2的一个重要设计

5. 实际传输的数据Payload，如果帧类型是HEADERS，那么这里存的就是请求头，如果帧类型是DATA ，那么这里存的就是请求体

通过这种设计，我们可以发现，我们就可以来压缩请求头了，比如如果帧的类型是HEADERS ，那就进行压缩，当然压缩算法是固定的HPACK算法，不能更换。

## 9.4 Triple源码分析

通过学习Dubbo协议，我们首先要知道我们启动服务的应该是在TripleProtocol

### 9.4.1 客户端处理

![](../assets/1ae2febba39ef447.png)

#### **调到TripleInvoker.doInvoke**

![](../assets/996cd83be1a6c576.png)

![](../assets/f7ca1ed368c090c9.png)

#### 发送数据

![](../assets/f61f32f89a26a981.png)

发送数据包括请求头和请求体

![](../assets/9471013e00e71dfd.png)

发送请求头

这里我们数据会放到队列，最后会调用到HeaderQueueCommand#doSend方法，发送数据

![](../assets/bcb4fc6355080ea8.png)

放入队列

先放到队列，然后会定时flush的时候进行处理

![](../assets/e9d4683fe6048fa2.png)

![](../assets/c2ddd838ed36fd30.png)

下面我们可以看到，当我发现有数据就会一直取知道128个后才发送，如果poll为空，则走下面内容数据不为空则发送

![](../assets/2c3dd643012ddac5.png)

刷新后则调用到HeaderQueueCommand#doSend方法

![](../assets/9836b12962016f44.png)

下面发送请求体和完成，与上面发送请求头都是异步处理，代码一样只是最后调用处理不同

**发送数据**

![](../assets/fbd92358bf7ffc92.png)

![](../assets/051db365c0ad608b.png)

上图我们可以看出，也是异步处理，最终会调用到DataQueueCommand#doSend方法

![](../assets/58e45654f2e2cc07.png)

#### 发送完成数据

![](../assets/207c54caeebd5f6f.png)

![](../assets/42bd4f85cb1e918d.png)

![](../assets/5377c4a1e8aaa50a.png)

![](../assets/2b674a2fa4283c2d.png)

最终会调用感到EndStreamQueueCommand.doSend方法

![](../assets/f80b050e1ce328ea.png)

### 9.4.2 服务端启动

![](../assets/0de35c7d84031233.png)

![](../assets/cf8a8a63a2e0b8bf.png)

![](../assets/fedb3aa2864d26d9.png)

![](../assets/7aa0eadc27321f9e.png)

进入启动Netty的源码

![](../assets/ebff6ed4d9f85c8e.png)

这里有个处理器NettyPortUnificationServerHandler，我们这里有的decode方法，他会识别我们是不是HTTP2协议

**怎样识别HTTP2协议？**

如果要建立的是一个HTTP2连接，那么在建立完Socket连接后,客户端立刻会发送一个连接前言，也就是一串字节

(对应的字符串为:"PRI\*HTTP/2.0\r\n\r\nSM\r\n\r\n")， 给到服务端，服务端从而知道要建立的是HTTP2

![](../assets/7147aea3bc06defc.png)

如果识别出RECOGNIZED，

![](../assets/86201bf9beb3238b.png)

![](../assets/7c3f5bcaa9b93689.png)

处理数据

![](../assets/4d0eb48c24eb6370.png)

#### 处理请求头

![](../assets/a0c9131293d7ee74.png)

![](../assets/bd27b8d20f53ac29.png)

![](../assets/3a7ed053000d580c.png)

![](../assets/2260f53a6e515398.png)

获取invoker

![](../assets/e9048f1e80745f73.png)

启动监听器

![](../assets/740f3e14803d53cd.png)

![](../assets/19c89f206b40a471.png)

![](../assets/0f5d747e72692451.png)

这里处理请求头获取了Invoker和对应的listener:UnaryServerCallListener 处理请求内容中会用到

#### **处理请求**

![](../assets/d084cccc21984933.png)

![](../assets/8d2f59c4cf8024f6.png)

![](../assets/474627e9de23302f.png)

##### 处理请求体

![](../assets/8dd4e30fc4076e56.png)

![](../assets/f15d5e51cc2ade0a.png)

![](../assets/52c760b34b1fe55c.png)

![](../assets/5c78a7d3b92142e7.png)

![](../assets/afd172ad14702aab.png)

这里只是给我们invoker设置了参数，但是没有立刻调用，而是在complete中进行调用

![](../assets/f0573aa9d8999297.png)

##### 处理完成帧

![](../assets/e076bc877ed602f0.png)

![](../assets/41e98b73c5a3039c.png)

![](../assets/3e3a399951bdd658.png)

![](../assets/b9b046c276f13e3c.png)

![](../assets/bf79f5af5c2ec040.png)

![](../assets/318efc31277a794f.png)

![](../assets/61cb34eeea7d61e9.png)

# 10、扩展点SPI

## 10.1 概念

SPI是一种软件编程模型，用于实现在运行时动态加载和扩展组件的能力。在Dubbo3中，SPI机制被广泛应用于扩展框架功能，允许用户自定义实现各种接口，以满足业务需求。

**Java中的SPI机制**

![](../assets/1c7f70a0cabcf3fa.png)

我们使用Mybatis操作数据库，那我们应该使用怎样操作mysql 或者oracle或者DB2呢？ 首先我们应该引入对应的Mysql的jar，我们利用这jar才能操作数据库，那对于JDBC操作DriveMananger获取链接的时候，他怎样获取Mysql的jar包中对应的类，来链接mysql呢

![](../assets/665d4df02f504218.png)

实例：

![](../assets/12acf9472d875bfa.png)

加载对应的配置

![](../assets/4d15d1712a283712.png)

![](../assets/c99637adc4f60ff4.png)

缺点：我们如果对应配置文件中com.msb.dubbo.provider.SPI.JDK.Course配置多个实现类，但是我们只需要EnglishCourse，所以为了效率我们只应该加载EnglishCourse，但是JDK的SPI会把所有的加载掉，所以Dubbo退出自己的SPI

![](../assets/066550557a4f1fdc.png)

![](../assets/8ad0cde2c91d3bf8.png)

![](../assets/ef8de52ef4100791.png)

Dubbo3 SPI演示

![](../assets/78d4984138335135.png)

![](../assets/491755212a85bb2e.png)

![](../assets/99300e538ece7243.png)

![](../assets/5809ee3c06c14f65.png)

![](../assets/19913a2032594cef.png)

![](../assets/68ecc0546ed9053b.png)

Wrapper包装（AOP）

![](../assets/3e1d925b20d6d890.png)

![](../assets/97bf921810a0fb23.png)

![](../assets/639026aeb072ffe9.png)

## 10.2源码分析

![](../assets/95b48715c57437ba.png)
