Spark 优化本质就是尽可能的减少无效数据计算、缓存数据、均匀分布数据，最大化资源利用，可以从以下几个角度进行SparkSQL优化。

## **开启AQE并设置合理的分区**

Spark3.2版本后自动开启了AQE查询，如果是其他版本Spark可以在使用SparkSQL时开启AQE自适应查询并将spark.sql.shuffle.partitoins设置适当的值来加快查询速度。

## **编写SQL尽量减少计算数据量**

编写SQL时尽可能在计算时减少数据输入量，可以在数据表关联时指定固定想要的字段或者在关联之前使用where对数据进行过滤，减少计算的数据量。

|  |
| --- |
| **#指定查询的固定列,避免使用星号查询**  select col1,col2 from tbl  **#查询时指定where条件**  select col1,col2 from tbl where id = xxx; |

## **对小表自动broadcast**

可以设置参数spark.sql.autoBroadcastJoinThreshold指定SparkSQL小表自动广播的阈值，默认是10M 。例如：大表和小表进行关联，内存如果充足情况下可以将该值调大，将小表广播出去避免shuffle操作。

## **对复杂查询进行拆解**

原始SQL查询嵌套较多或者非常复杂时，可以考虑将复杂查询语句进行拆解成多个查询子句，这样可以加快SQL查询速度并可以做到数据表的复用。

例如：多个大表进行Join，其中各个表涉及到数据的过滤、聚合等，可以针对每个表进行拆分将每个表单独处理获取中间临时表，然后对中间临时表进行关联操作。

## **对重复使用的数据表进行持久化**

如果对SparkSQL计算过程中的中间表经常复用，可以考虑将该表使用persist()持久化，将数据表持久化到磁盘或者内存中，避免再次使用时重新计算。

|  |
| --- |
| **#持久化**  df.persist(StorageLevel.MEMORY\_ONLY)  spark.catalog.cacheTable(“tableName”)  **#删除持久化数据**  df.unpersist()  spark.catalog.uncacheTable(“tableName”) |

## **数据倾斜处理**

在SparkSQL处理过程中如果数据有倾斜，例如：10%的 key, 占了 90%的数据量, 而拿 key 去关联的话，那10%的key就会出现明显的数据倾斜，可以对倾斜的key进行加盐处理，加盐处理的原理就是通过随机值将 10%的key 打平，从而均分数据量，平均每个节点的压力，从而减少数据倾斜的情况。可以开启AQE自动处理，但需要设置对应的倾斜分区阈值参数。

## **合理使用各个分析函数**

- row\_number() over (partition by ... order by ...)：同个分组内生成连续的序号，每个分组内从1开始且排序相同的数据会标不同的号。
- rank() over (partitin by ... order by ... ) 同个分组内生成不连续的序号，在每个分组内从1开始，同个分组内相同数据标号相同。
- dense\_rank() over (partitin by ... order by ... )同个分组内生成连续的序号，在每个分组内从1开始，同个分组内相同数据标号相同，之后的数据标号连续。
- sum(...) over(partition by ... order by ...):按照order by列累计结果，累计到当前行。
- sum(...) over(partition by ... order by ... rows between 1 preceding and current row)：按照order by列累计结果，前一条数据累计到当前行。
- sum(...) over(partition by ... order by ... rows between 1 preceding and 1 following):按照order by列累计结果，累计前1行、当前行、后一行数据结果。
- explode（list）：爆炸函数，将集合数据展开为每一条数据。
- get\_json\_object($"infos","$.name") ：从json中获取json属性值。
- concat(col1,col2):将多列拼接成一列
- concat\_ws("分隔符",col1,col12) ：可以指定分隔符隔开字段,形成新列。
- collect\_list(col1): 使用时需要使用group by 对某个字段分组，然后对其他的某个字段下的数据放在一个集合中，不去重
- collect\_set(col1): 与collect\_list一样，去重
- split(col1,“分隔符”)：按照分隔符切割列
- str\_to\_map(字符串,Delimiter1，Delimiter2)：使用两个分隔符将文本拆分为键值对。 Delimiter1 将文本分成K-V对，默认分隔符为“,”。Delimiter2分割每个K-V对，默认分隔符为“=”，例如：str\_to\_map("A=100,B=200,C=300",",","=")
- unix\_timestamp : 将字符串时间转换成是时间戳,例如：unix\_timestamp(‘20250401’,‘yyyyMMdd’)
- from\_unixtime：时间戳转换成是时间，from\_unixtime(时间戳，‘yyyy-MM-dd’)
- datediff(date1,date2): 获取时间差值，例如：datediff(‘2025-05-01’，‘2025-05-02’)
- date\_add(date，days):时间增加天数,例如：date\_add('2025-01-01', 10)
- 其他时间函数：year()、month()、day()、hour()、minutes()
