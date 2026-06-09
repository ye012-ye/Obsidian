## 事务处理上方面

（1）MyISAM：强调的是性能，每次查询具有原子性,其执行速度比InnoDB类型更快，但是不提供事务支持。

（2）InnoDB：提供事务支持事务，外部键等高级数据库功能。具有事务(commit)、回滚(rollback)和崩溃修复能力(crash recovery capabilities)的事务安全(transaction-safe (ACID compliant))型表。

锁级别

（1）MyISAM：只支持表级锁，用户在操作MyISAM表时，select，update，delete，insert语句都会给表自动加锁，如果加锁以后的表满足insert并发的情况下，可以在表的尾部插入新的数据。

（2）InnoDB：支持事务和行级锁，是innodb的最大特色。行锁大幅度提高了多用户并发操作的性能。但是InnoDB的行锁，只是在WHERE的主键是有效的，非主键的WHERE都会锁全表的。
