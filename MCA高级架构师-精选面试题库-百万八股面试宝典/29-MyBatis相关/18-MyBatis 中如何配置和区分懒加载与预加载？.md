MyBatis 通过全局设置与映射级别配置两种方式控制关联对象的加载方式：M

#### 1. 全局配置

- 在 `mybatis-config.xml` 中，通过设置 `<setting name="lazyLoadingEnabled" value="true"/>` 启用懒加载功能，默认是 `false`（预加载），启用后关联对象默认延迟加载。
- 可选设置 `<setting name="aggressiveLazyLoading" value="false"/>`：关闭后仅在首次访问对应字段时触发加载，避免调用 `toString()`、`equals()` 等触发全部加载。

#### 2. 映射文件级配置

在 `<association>` 或 `<collection>` 标签中使用 `fetchType` 覆盖全局设置，例如：

```xml
<association property="addr" javaType="Address" column="addr_id"
  select="selectAddressById" fetchType="lazy"/>
```

- `fetchType="lazy"`：关联属性按需加载；
- `fetchType="eager"`：关联属性立即加载。

S

### 区别与触发方式：

- **懒加载（lazy）**：仅在调用属性 getter 方法（或触发配置的 trigger 方法）时才查询数据库，适合关联对象不一定使用的场景，减少不必要的查询，防止 N+1 问题需谨慎控制。
- **预加载（eager）**：主查询时立即加载关联数据，适合后续必用的关联场景，可通过 JOIN 或多表查询一次加载。

B

### 示例：

```xml
<resultMap id="userMap" type="mashibingUser">
  <id property="id" column="id"/>
  <association property="address" javaType="mashibingAddress"
    column="address_id" select="selectAddressById"
    fetchType="lazy"/>
</resultMap>
```

若设置 `lazyLoadingEnabled=true`，并开启 `aggressiveLazyLoading=false`，则在如下调用：

```java
mashibingUser u = mapper.selectUserById(1);
// 此时 address 不会被加载
String city = u.getAddress().getCity(); // 此刻触发懒加载查询
```
