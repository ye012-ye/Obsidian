Spring 利用 **三级缓存机制 + 提前暴露半成品 Bean + 延迟代理** 来破除循环依赖，核心流程如下：

### 1. 实例化并加入三级缓存（ObjectFactory）

当调用 `doCreateBean()` 生成一个 Bean 实例时，Spring 会通过 `addSingletonFactory(beanName, () -> getEarlyBeanReference(...))` 将一个 `ObjectFactory` 放入 **第三级缓存（singletonFactories）**，负责在必要时创建半成品 Bean 或代理对象。

M

### 2. 触发属性依赖注入时递归获取依赖 Bean

执行 `populateBean()` 时，若当前 Bean 依赖另一个正在创建的 Bean，`getSingleton(beanName, true)` 会依次从缓存中尝试获取：

- 一级缓存 `singletonObjects`: 完整 Bean
- 二级缓存 `earlySingletonObjects`: 已生成但未初始化的半成品
- 三级缓存 `singletonFactories`: 若存在，则调用其 `getObject()`，生成半成品/代理并推入二级缓存，同时移除三级缓存的 factory，最后返回给依赖者

S

### 3. 完成初始化，升级到一级缓存

依赖注入完毕后，Spring 继续执行 `initializeBean()`，包括 `@PostConstruct`、`InitializingBean`、和后置处理器，完成 Bean 的初始化或生成代理。随后，调用 `addSingleton()` 将该 Bean 放入 **一级缓存**，并清理二级与三级缓存的对应记录。

### 4. 清除缓存，返回最终 Bean 实例

初始化完成后的 Bean 被存于一级缓存，后续 `getBean()` 直接返回，不再重复创建；二级与三级缓存中对应 entry 被清理，避免重复处理和无谓资源占用。

B
