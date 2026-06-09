Spring 自动装配主要分为以下几种模式，配合注解使用时需开启注解驱动（如 `@ComponentScan`, `<context:annotation-config>`）：

M

### 1. XML 模式（`autowire` 属性）

- **byName**（按名称匹配）  
  容器会尝试根据属性名找到同名 Bean 并通过 setter 注入，如 `setDept(Department dept)` 会匹配 `id="dept"` 的 Bean。《byName》模式依赖属性名及 Bean 名称一致。
- **byType**（按类型匹配）  
  容器根据属性类型查找唯一 Bean，如属性类型为 `Department`，容器中有且只有一个匹配 Bean 时注入。类型不唯一会报错。
- **constructor**（构造器注入）  
  容器选择匹配构造器参数类型的 Bean 进行注入，适合依赖必须提供的情况，如 `public A(B b, C c)`。
- **autodetect**（自动检测）  
  先尝试 constructor，若失败则退回 byType。仅适用于早期 Spring 版本，后已渐被弃用

S

### 2. 注解方式（`@Autowired` + `@Qualifier` 等）

- **按类型自动注入（默认）**  
  `@Autowired` 放在字段、构造函数或 setter 上，Spring 先按类型查找 Bean 注入。
- **按名称或自定义注入**  
  配合 `@Qualifier("beanName")` 指定注入哪个 Bean，也可通过字段名+Bean名匹配（类似 byName）。
- **构造函数注入推荐方式**  
  添加 `@Autowired` 到构造函数上，实现强类型注入，推荐用于强依赖组件，增强不可变性与可测试性。B
