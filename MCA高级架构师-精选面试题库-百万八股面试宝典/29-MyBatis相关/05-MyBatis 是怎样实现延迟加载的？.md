MyBatis 的延迟加载（lazy loading）机制是在初始化阶段按需加载关联对象，通过动态代理触发子查询，从而实现性能优化。

M

延迟加载需在配置文件中启用：

```xml
<settings>
  <setting name="lazyLoadingEnabled" value="true"/>
  <setting name="aggressiveLazyLoading" value="false"/>
</settings>
```

- `lazyLoadingEnabled=true` 启用延迟加载；
- `aggressiveLazyLoading=false` 确保仅在调用属性时触发，而不是对对象的任何方法调用都加载({turn0search4}).  
  此外，在关联映射中指定 `fetchType="lazy"` 覆盖全局配置。

S

执行查询时，MyBatis 在 `DefaultResultSetHandler` 的 `createResultObject` 阶段，会为标记为 `lazy` 的关联属性生成代理对象。默认通过 Javassist（也支持 CGLIB）创建代理，用于拦截 `getXxx()` 方法调用。

​

代理对象封装了对应的查询逻辑，内部保存 `ResultLoader`。当首次调用该属性的 getter（或其他触发方法如 `equals`, `hashCode`, `toString`）时，代理拦截调用并执行子查询，加载真实关联对象并替换代理自身，若 `aggressiveLazyLoading=true`，则任何触发方法会加载所有延迟属性；开启 `false` 则仅按需属性加载。

B

延迟加载虽能减少一次性加载开销，却可能引发 N+1 查询问题：若对多个父对象依次访问关联属性，会重复执行子查询，导致性能下降。因此需谨慎启用，或在需要时使用 JOIN 查询一次性加载。

#### 总结

MyBatis 延迟加载通过以下方式实现优化与灵活性：

- 通过配置控制是否按需加载；
- 利用动态代理封装关联查询逻辑；
- 在第一次访问关联属性时触发加载；
- 适合场景是关联复杂但不总会用到的属性，但需避免 N+1 查询造成性能问题。
