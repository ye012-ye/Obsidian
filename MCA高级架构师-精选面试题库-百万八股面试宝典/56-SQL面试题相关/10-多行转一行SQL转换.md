行列变换操作，数据如下：

|  |  |  |
| --- | --- | --- |
| **username** | **item** | **price** |
| zhangsan | A | 1 |
| zhangsan | B | 2 |
| zhangsan | C | 3 |
| zhangsan | D | 4 |
| lisi | A | 5 |
| lisi | B | 6 |
| lisi | C | 7 |
| wangwu | A | 8 |

要求获取以下结果,同时将结果再次转换成以上表格（Price除外）：

|  |  |  |
| --- | --- | --- |
| **username** | **item** | **price** |
| zhangsan | A,B,C,D | 10 |
| lisi | A,B,C | 18 |
| wangwu | A | 8 |

数据row-col.txt数据：

|  |
| --- |
| username,item,price  zhangsan,A,1  zhangsan,B,2  zhangsan,C,3  zhangsan,D,4  lisi,A,5  lisi,B,6  lisi,C,7  wangwu,A,8 |

代码：

|  |
| --- |
| **val** session: SparkSession = SparkSession.*builder*().master(**"local"**).appName(**"test"**).getOrCreate() session.sparkContext.setLogLevel(**"Error"**) **val** df = session.read.option(**"header"**,**true**).csv(**"./data/row-col.txt"**)  df.createTempView(**"temp"**)  session.sql(  **"""**  **| select**  **| username,concat\_ws(",",collect\_list(item)) as items , sum(price) as total\_price**  **| from temp**  **| group by username**  **"""**.stripMargin).createTempView(**"temp1"**)  session.sql(  **"""**  **| select**  **| username,explode(split(items,",")) as item,total\_price**  **| from temp1**  **"""**.stripMargin).show() |
