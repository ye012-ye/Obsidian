Dubbo 的泛化调用（Generic Service）是一种弱类型调用机制，允许消费者在不依赖服务 API 接口或模型类的情况下，通过反射进行远程调用。它解决了接口不可知、跨语言调用和动态调用场景中的依赖问题。M

### 定义与原理

泛化调用依赖于 `org.apache.dubbo.rpc.service.GenericService` 接口，它定义了一个 `$invoke(String method, String[] paramTypes, Object[] args)` 方法。消费者通过构造方法名、参数类型字符串数组以及对应参数值来发起调用。框架底层通过反射调用提供者对应接口的方法。  
所有参数和返回值中涉及的 POJO 都会被序列化为 `Map<String, Object>`，并在传输过程中完成类型转换与序列化。

### 适用场景

- **API 网关或测试平台**：不想随每个服务发布而频繁更新网关代码，可直接通过泛化调用调用任意服务。
- **跨语言调用**：当消费者与提供者使用不同语言且无法共享接口定义时，实现弱耦合调用。
- **接口调试或动态环境**：提供快速验证能力，无需重启或编译接口代码。S

production 场景如 vivo 在统一配置平台中使用泛化调用来减少网关对接口包的依赖。

### 使用方式

#### Consumer 端

**XML 配置：**

```xml
<dubbo:reference id="userService"
  interface="com.foo.UserService"
  generic="true"/>
```

然后：

```java
GenericService svc = (GenericService) applicationContext.getBean("userService");
Object result = svc.$invoke(
    "getUser",
    new String[]{"com.foo.Params"},
    new Object[]{paramMap});
```

返回结果为 `Map<String,Object>`。

**API 方式：**

```java
ReferenceConfig<GenericService> ref = new ReferenceConfig<>();
ref.setInterface("com.foo.UserService");
ref.setGeneric(true);
GenericService svc = ref.get();
svc.$invoke("method", types, args);
```

#### Provider 端

可以直接暴露常规模块，无需额外代码。也可实现 `GenericService` 接口自行处理所有调用：B

```java
public class MyGenericImpl implements GenericService {
    public Object $invoke(String method, String[] types, Object[] args) { ... }
}
```
