自 Spring Boot 2.6.0 起，默认 `spring.main.allow-circular-references=false`，即启动时若检测到 bean 之间存在循环依赖就会报错。这一决策源于以下几点考虑：

首先，**循环依赖往往反映设计不合理**。当 class A 依赖于 B，B 又依赖于 A 时，表明模块划分不清晰、职责不够聚焦，未来维护与扩展都会变得混乱。Spring Boot 禁止这种结构，是希望迫使开发者重构代码，避免陷入“擦屁股式”的补救地步。M

其次，Spring 的三级缓存机制虽然可以通过设置 `allow-circular-references=true` 处理循环依赖，但其只是权宜之计，**隐藏了潜在的复杂问题**，掩盖了设计缺陷。Boot 团队希望避免引导开发者依赖这种机制，而是从根本上重构耦合关系。S

再次，从技术机制角度看，Spring Boot 在 bean 创建阶段使用依赖堆栈检测循环。如果检测到环形结构，特别是构造器注入的循环，就会立即抛出 `BeanCurrentlyInCreationException`，而不延迟处理，以避免执行不确定性。B

当然，为了兼容历史项目，提供了配置回退选项：

```yaml
spring:
  main:
    allow-circular-references: true
```

但这是**临时措施**，官方仍建议彻底消除循环依赖，使用设计优化、`@Lazy` 延迟注入 or `ObjectFactory` 等方案重构。总之，从 2.6 起，Spring Boot 明确表达：**设计要清晰，依赖不可任性**。
