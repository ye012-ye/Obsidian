### 一、关系定位

Spring Framework 是一个完整的应用框架，提供核心功能（如 IoC 注入、AOP、事务管理、MVC、数据访问等），适用于复杂企业系统的架构搭建。而 Spring Boot 是对 Spring 的增强扩展，用于简化项目搭建，减少配置工作，实现快速启动和部署。可以理解为，Spring Boot 是构建在 Spring 基础上的“快速启动器”。

### 二、核心区别

|  |  |  |
| --- | --- | --- |
| **对比维度** | **Spring Framework** | **Spring Boot** |
| **配置方式** | 需显式配置 XML 或 Java 注解，手工 wired Bean 等 | 自动配置 + starter 依赖，简化 `application.yml` 与注解使用 |
| **启动方式** | 常部署为 WAR 到外部容器，如 Tomcat | 内嵌服务器（Tomcat/Jetty/Undertow），通过 `java -jar` 启动 |
| **依赖管理** | 手动管理各模块版本 | 使用 Starter 起步依赖，自动继承 BOM 版本管理 |
| **功能接入** | 集成各模块需逐个引入，配置侵入较强 | 自动装配常用模块，原理依据 Classpath 和属性判断 |
| **生产监控** | 需自行引入库（如 Micrometer、Actuator、Health） | 内置 Actuator，增强监控与管理特性 |
| **适用场景** | 适合对配置、容器控制有高要求的复杂系统 | 适合微服务、原型开发、云部署，启动快、开发体验好 |
