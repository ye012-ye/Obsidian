数据转换：

|  |  |  |
| --- | --- | --- |
| **dt** | **cn** | **point** |
| 1 | abc | 10 |
| 1 | def | 15 |
| 1 | xyz | 20 |
| 2 | abc | 13 |
| 2 | xyz | 40 |
| 3 | def | 50 |
| 3 | abc | 60 |
| ... | ... | ... |

查询转换成如下结构:

|  |  |  |
| --- | --- | --- |
| **cn** | **dt** | **sumpoint** |
| abc | 1 | 10 |
| def | 1 | 15 |
| xyz | 1 | 20 |
| abc | 2 | 23 |
| xyz | 2 | 60 |
| def | 3 | 65 |
| abc | 3 | 83 |
| ... | ... | ... |

数据data.txt数据：

|  |
| --- |
| 1 abc 10  1 def 15  1 xyz 20  2 abc 13  2 xyz 40  3 def 50  3 abc 60 |

SQL建表语句：

|  |
| --- |
| create table temp (dt string,cn string ,point int ) row format delimited fields terminated by '\t'; |

SQL结果:

|  |
| --- |
| select cn,dt,sum(point) over(partition by cn order by dt) as sumpoint from temp order by dt; |
