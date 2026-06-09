Spring AOP 支持五种通知（Advice），它们在方法执行生命周期中的触发方式和顺序略有不同，理解这些对保证切面逻辑准确执行至关重要。

M

### 1. 通知类型说明

- **@Around**：环绕通知，最有权威，可在方法调用前后执行逻辑，并可决定是否继续执行目标方法。
- **@Before**：前置通知，在目标方法执行前触发。
- **@After**：后置（finally）通知，目标方法无论是否抛异常，都会执行。
- **@AfterReturning**：返回通知，仅在目标方法成功执行后触发。
- **@AfterThrowing**：异常通知，仅在目标方法抛出异常时触发。

S

### 2. 同一切面内通知的执行优先级（Spring 5.2.7+）

按照 Spring 和 AspectJ 的规范，同一 `@Aspect` 类中，多种通知类型的调用顺序为（优先级从高到低）：

```less
@Around → @Before → @After → @AfterReturning → @AfterThrowing
```

但实际执行顺序会有微调：

- 方法正常执行（无异常）时：  
  `@Around(before)` → `@Before` → *目标方法* → `@Around(after)` → `@AfterReturning` → `@After`
- 方法抛异常时：  
  `@Around(before)` → `@Before` → *目标方法*（抛异常） → `@Around(after?)` → `@AfterThrowing` → `@After`

B

### 3. 多个切面之间的排序

- 如果多个切面（Aspect）中的通知应用于同一个连接点，默认执行顺序不确定。
- 可以使用 `@Order` 注解或实现 `Ordered` 接口设置切面的优先级，数字越小优先级越高（先执行 entry，最后执行 exit）。
