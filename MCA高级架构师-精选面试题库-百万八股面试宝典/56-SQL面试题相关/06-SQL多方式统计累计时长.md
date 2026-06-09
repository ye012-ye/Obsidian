有用户每日游戏时长数据如下：

|  |  |  |
| --- | --- | --- |
| **uid** | **dt** | **duration** |
| uid1 | 2021-02-20 | 1 |
| uid1 | 2021-02-21 | 2 |
| uid1 | 2021-02-22 | 3 |
| uid2 | 2021-02-20 | 3 |
| uid2 | 2021-02-21 | 5 |
| uid2 | 2021-02-22 | 6 |
| uid3 | 2021-02-20 | 7 |
| uid3 | 2021-02-21 | 8 |
| uid3 | 2021-02-22 | 9 |
| uid4 | 2021-02-23 | 10 |

要求使用SparkSQL统计以下信息:

1. 统计每个用户每天游戏累计时长。(要求同一用户每天游戏时长累加之前所有天的游戏时长）
2. 统计每个用户每天游戏时长累加前一天游戏时长的累计时长。
3. 统计每个用户每天游戏时长累加后一天游戏时长的累计时长。

数据UserPlayData.txt数据如下：

|  |
| --- |
| uid,dt,duration  uid1,2021-02-20,1  uid1,2021-02-21,2  uid1,2021-02-22,3  uid2,2021-02-20,3  uid2,2021-02-21,5  uid2,2021-02-22,6  uid3,2021-02-20,7  uid3,2021-02-21,8  uid3,2021-02-22,9  uid4,2021-02-23,10 |

代码实现：

|  |
| --- |
| 1. 统计每个用户每天游戏累计时长。   session.sql(  **"""**  **| select uid,dt,duration,sum(duration) over(partition by uid order by dt) as rt from temp**  **"""**.stripMargin).show()     1. 统计每个用户每天游戏时长累加前一天游戏时长的累计时长。   session.sql(  **"""**  **|select uid,dt,duration,sum(duration) over (partition by uid order by dt rows between 1 preceding and current row) as rt from temp**  **"""**.stripMargin).show()     1. 统计每个用户每天游戏时长累加后一天游戏时长的累计时长。   session.sql(  **"""**  **| select uid,dt,duration,sum(duration) over (partition by uid order by dt rows between current row and 1 following) as dt from temp**  **"""**.stripMargin).show() |
