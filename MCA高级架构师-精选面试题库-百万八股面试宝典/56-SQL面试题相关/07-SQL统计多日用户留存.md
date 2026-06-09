有如下数据，用户注册信息表和用户登录信息表：

用户注册信息表 regist\_infos：

|  |  |  |
| --- | --- | --- |
| **uid** | **regist\_dt** | **regist\_os** |
| u1 | 20210301 | android |
| u2 | 20210301 | android |
| u3 | 20210301 | iphone |
| u4 | 20210302 | android |
| u5 | 20210302 | iphone |
| u6 | 20210303 | android |
| u7 | 20210303 | android |
| u8 | 20210304 | iphone |
| u9 | 20210304 | iphone |

用户登录信息表 login\_infos：

|  |  |
| --- | --- |
| **uid** | **login\_dt** |
| u1 | 20210301 |
| u1 | 20210301 |
| u2 | 20210301 |
| ... | ... |

SparkSQL统计注册日后1日、2日、3日、4日、5日、6日、7日用户留存数。期望得到的结果(此结果与上面结果无关)：

|  |  |  |
| --- | --- | --- |
| **regist\_dt** | **days** | **cnt** |
| 20210301 | 1 | 2 |
| 20210301 | 2 | 2 |
| 20210302 | 5 | 3 |
| ... | ... | ... |

regist\_infos.csv数据：

|  |
| --- |
| uid regist\_dt regist\_os  u1 20210301 android  u2 20210301 android  u3 20210301 iphone  u4 20210302 android  u5 20210302 iphone  u6 20210303 android  u7 20210303 android  u8 20210304 iphone  u9 20210304 iphone |

login\_infos.csv数据：

|  |
| --- |
| uid login\_dt  u1 20210301  u1 20210301  u2 20210301  u2 20210301  u3 20210301  u1 20210302  u2 20210302  u3 20210302  u4 20210302  u5 20210302  u1 20210303  u2 20210303  u3 20210303  u4 20210303  u5 20210303  u6 20210303  u6 20210303  u7 20210303  u1 20210304  u2 20210304  u3 20210304  u4 20210304  u5 20210304  u6 20210304  u7 20210304  u8 20210304  u9 20210304  u1 20210305  u2 20210305  u3 20210305  u4 20210306  u5 20210306  u6 20210306  u7 20210307  u8 20210307  u9 20210307  u1 20210308  u3 20210308  u3 20210308 |

SparkSQL代码实现：

|  |
| --- |
| **val** session: SparkSession = SparkSession.*builder*().master(**"local"**).appName(**"test"**).getOrCreate() session.sparkContext.setLogLevel(**"Error"**) **val** registInfos: DataFrame = session.read.option(**"header"**,**true**).csv(**"./data/regist\_infos.csv"**)**val** loginInfos: DataFrame = session.read.option(**"header"**,**true**).csv(**"./data/login\_infos.csv"**)  registInfos.createTempView(**"regist\_infos"**) loginInfos.createTempView(**"login\_infos"**)  session.sql(  **"""**  **| select**  **| a.uid,a.regist\_dt,b.uid,b.login\_dt,**  **| datediff(from\_unixtime(unix\_timestamp(b.login\_dt,"yyyyMMdd"),"yyyy-MM-dd"),from\_unixtime(unix\_timestamp(a.regist\_dt,"yyyyMMdd"),"yyyy-MM-dd")) as diff**  **| from regist\_infos a join (select distinct uid,login\_dt from login\_infos) b**  **| on a.uid = b.uid**  **| where b.login\_dt > a.regist\_dt**  **"""**.stripMargin).createTempView(**"temp"**)  session.sql(  **"""**  **| select regist\_dt,diff,login\_dt,count(\*) as cnt from temp**  **| group by regist\_dt,diff,login\_dt**  **| order by regist\_dt ,diff**  **"""**.stripMargin).show(100) |
