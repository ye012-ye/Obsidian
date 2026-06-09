InnoDB 引擎在以下场景中会主动施加各种锁以保障事务隔离和数据一致性：M

1. **执行写操作或带锁查询时**  
   对 `INSERT`、`UPDATE`、`DELETE` 以及 `SELECT … FOR UPDATE/SHARE`，InnoDB 会在涉及行上加上专属锁或共享锁，直到事务结束时释放锁。
2. **REPEATABLE‑READ 隔离级下范围查询**  
   默认使用 `next-key lock`（行锁 + 前置 gap lock）来防止重复读造成幻读。
3. **INSERT 操作的意图锁（Insert Intention Lock）**  
   在 gap 上表明插入意图，使多个事务可在相同 gap 中插入不同值而不冲突。
4. **AUTO\_INCREMENT 的表级锁**  
   插入带 `AUTO_INCREMENT` 字段的记录时，为保证值的顺序性，InnoDB 会为整个表加锁，释放时限于当前语句或事务。S
5. **显式表级锁操作**  
   通过 `LOCK TABLES ... READ/WRITE` 手动对整张表加锁，用于全表读写或备份等场景。
6. **元数据锁（MDL）**  
   执行 `ALTER TABLE`、`DROP TABLE` 等 DDL 操作时，会对表结构加元数据锁，防止与其它 DML/DDL 冲突。B
