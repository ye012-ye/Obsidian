|  |  |  |  |
| --- | --- | --- | --- |
| **app** | **channel** | **province** | **userid** |
| 消消乐 | ios | 北京 | abc |
| 王者荣耀 | Android | 上海 | cde |

需求:求app,channel,province任意组合下的用户数，用一个sql实现，上面一条记录会产生多条记录。

数据testdata.txt数据：

|  |
| --- |
| 消消乐 ios 北京 abc  王者荣耀 Android 上海 cde |

创建表SQL语句：

|  |
| --- |
| create table test (app string,channel string,province string,userid string) row format delimited fields terminated by '\t'; |

SQL结果：

|  |
| --- |
| select app,channel,province,count(userid) as total\_user\_cnt from test group by app,channel,province with cube;    with cube : 所有列任意组合。  with rollup:生成的结果集显示了所选列中值的某一层次结构的聚合。  grouping sets((x1,x2),(x1,x2,x3))：指定组合。 |
