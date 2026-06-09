有如下数据，三列分别为服务器ID、记录时间、服务器状态，建表并将数据加载到表中，按照要求统计指标。

|  |
| --- |
| **#数据**  server1,2025-01-01 00:00:00,运行中  server1,2025-01-01 01:00:00,运行中  server1,2025-01-01 02:00:00,停止  server1,2025-01-01 03:00:00,维护中  server2,2025-01-01 00:00:00,运行中  server2,2025-01-01 01:00:00,维护中  server2,2025-01-01 02:00:00,维护中  server2,2025-01-01 03:00:00,运行中  server3,2025-01-01 00:00:00,停止  server3,2025-01-01 01:00:00,停止  server3,2025-01-01 02:00:00,运行中  server3,2025-01-01 03:00:00,维护中  **#建表并加载数据**  CREATE TABLE server\_status (  server\_id STRING,  record\_time STRING,  server\_status STRING  )  row format delimited fields terminated by ',';  load data inpath '/data.txt' into table server\_status; |

根据以上表数据，统计每个服务器状态相比于上一条数据变化的数据条目。

|  |
| --- |
| **#sql**  with temp as (  select server\_id,record\_time,server\_status,  lag(server\_status,1) over(partition by server\_id order by record\_time) as flag  from server\_status  )  select server\_id,record\_time,server\_status  from temp  where flag is not null and server\_status != flag;  **#结果**  +------------+----------------------+----------------+  | server\_id | record\_time | server\_status |  +------------+----------------------+----------------+  | server1 | 2025-01-01 02:00:00 | 停止 |  | server1 | 2025-01-01 03:00:00 | 维护中 |  | server2 | 2025-01-01 01:00:00 | 维护中 |  | server2 | 2025-01-01 03:00:00 | 运行中 |  | server3 | 2025-01-01 02:00:00 | 运行中 |  | server3 | 2025-01-01 03:00:00 | 维护中 |  +------------+----------------------+----------------+ |
