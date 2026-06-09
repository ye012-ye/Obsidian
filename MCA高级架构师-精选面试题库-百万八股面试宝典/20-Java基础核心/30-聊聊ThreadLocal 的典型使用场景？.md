`ThreadLocal` 在 Java 中用于为每个线程提供独立的变量副本，常见场景包括：S

1. **Web 请求上下文管理**  
   如 Spring 中 `RequestContextHolder`、`SecurityContextHolder` 等，通过 `ThreadLocal` 保存当前线程请求、用户、事务等信息，无需在方法间反复传参。M
2. **数据库连接或事务资源管理**  
   为每个线程绑定单独的数据库连接或事务上下文，在整个执行流程中复用，提高性能并简化编程。例如在 DAO 层通过 `ThreadLocal<Connection>` 获取连接，确保线程安全。S
3. **日志追踪与 MDC 整合**  
   使用 `ThreadLocal` 保存当前线程特定日志上下文（如 traceId），结合 SLF4J 的 MDC，在日志输出中自动附加上下文信息，有助于问题排查。B
