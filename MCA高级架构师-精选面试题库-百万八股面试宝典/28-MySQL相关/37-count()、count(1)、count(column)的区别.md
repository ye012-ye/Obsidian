参考回答：

（1）count()对行的数目进行计算,包含NULL

（2）count(column)对特定的列的值具有的行数进行计算,不包含NULL值。

（3）count()还有一种使用方式,count(1)这个用法和count()的结果是一样的。

性能问题:

（1）任何情况下

SELECT COUNT() FROM tablename

都将是最优选择;

（2）尽量减少

SELECT COUNT() FROM tablename WHERE COL = ‘value’

这种查询;

（3）杜绝

SELECT COUNT(COL) FROM tablename WHERE COL2 = ‘value’

的出现。

（4）如果表没有主键,那么count(1)比count()快。

（5）如果有主键,那么count(主键,联合主键)比count()快。

（6）如果表只有一个字段,count()最快。

（7）count(1)跟count(主键)一样,只扫描主键。count()跟count(非主键)一样,扫描整个表。明显前者更快一些。
