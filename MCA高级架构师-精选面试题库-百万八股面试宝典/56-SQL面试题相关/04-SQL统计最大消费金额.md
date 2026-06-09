已知：有如下table（名syc\_mianshi），含有三个字段，姓名Name(string)，消费时间DT（string），消费金额Money(Double)，记录条数有若干行。

|  |  |  |
| --- | --- | --- |
| **NAME** | **DT** | **MONEY** |
| 张三 | 2015/10/4 | 300 |
| 张三 | 2015/4/16 | 200 |
| 张三 | 2015/5/9 | 600 |
| 李四 | 2015/1/17 | 2500 |
| 李四 | 2016/2/9 | 3700 |
| 王五 | 2015/5/12 | 0.4 |
| 王五 | 2015/12/23 | 1.23 |
| 王五 | 2014/3/20 | 0.56 |

计算每个人在哪一天的消费金额最大，即应输出：

|  |  |
| --- | --- |
| 张三 | 2015/5/9 |
| 李四 | 2016/2/9 |
| 王五 | 2015/12/23 |

数据SYC\_mianshi.txt数据：

|  |
| --- |
| 张三 2015/10/4 300  张三 2015/4/16 200  张三 2015/5/9 600  李四 2015/1/17 2500  李四 2016/2/9 3700  王五 2015/5/12 0.4  王五 2015/12/23 1.23  王五 2014/3/20 0.56 |

建表语句SQL:

|  |
| --- |
| create table syc\_mianshi (name string,dt string,money double) row format delimited fields terminated by '\t'; |

SQL结果：

|  |
| --- |
| load data local inpath '/root/mytestdata/syc\_mianshi.txt' into table syc\_mianshi;    set hive.exec.mode.local.auto=true;    select name ,dt ,money from (select name,dt,money,row\_number() over(partition by name order by money desc) as rank from syc\_mianshi) a where a.rank = 1; |
