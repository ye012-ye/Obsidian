有如下用户登录明细表tb\_cuid\_1d，一个用户可能对应多条记录:

|  |  |  |  |
| --- | --- | --- | --- |
| **字段名** | **字段含义** | **字段类型** | **字段示例** |
| cuid | 用户的唯一标识  (不同用户cuid不同) | string | ed2s9w |
| os | 平台 | string | android |
| soft\_version | 版本 | string | 11.0.0.1 |
| every\_day | 日期 | string | 20190101 |
| ext | 扩展字段 | array | [{},{},{}] |

数据示例：

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| cuid | os | soft\_version | every\_day | ext |
| A1 | Android | 11.0.0.1 | 20200401 | [{“id”:10001,”type”:”show”,”from”:”home”,”source”:”his”},{“id”:1002,”type”:”click”,”from”:”swan”,”source”:”rcm”},{“id”:1003,”type”:”slide”,”from”:”tool”,”source”:”banner”},{“id”:1001,”type”:”del”,”from”:”wode”,”source”:”myswan”}] |

文件data.txt数据：

|  |
| --- |
| A1 IOS 11.0.0.1 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A2 Android 11.0.0.2 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A3 Android 11.0.0.2 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A4 Android 11.0.0.3 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A5 Symbian 11.0.0.2 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 windows 11.0.0.1 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 IOS 11.0.0.1 20200401 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Symbian 12.0.0.1 20200402 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A2 IOS 13.0.0.1 20200402 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Android 14.0.0.1 20200403 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Symbian 15.0.0.1 20200404 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Android 16.0.0.1 20200405 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Symbian 17.0.0.1 20200406 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A1 Symbian 18.0.0.1 20200407 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"}  A2 Symbian 19.0.0.1 20200408 {"id":10001,"type":"show","from":"home","source":"his"}#{"id":1002,"type":"click","from":"swan","source":"rcm"}#{"id":1003,"type":"slide","from":"tool","source":"banner"}#{"id":1001,"type":"del","from":"wode","source":"myswan"} |

SQL建表语句：

|  |
| --- |
| create table tb\_cuid\_1d (cuid string,os string,soft\_version string,every\_day string,ext string) row format delimited fields terminated by '\t'; |

## 写出用户表 tb\_cuid\_1d的 20200401 的次日、次7日留存的具体HQL ：一条sql统计出以下指标 （4.1号uv，4.1号在4.2号的留存uv，4.1号在4.8号的留存uv）

|  |
| --- |
| select t3.every\_day,t3.diff,count(distinct t3.cuid) as cnt from (select t1.cuid,t1.os,t1.soft\_version,t1.every\_day,datediff(t2.new\_date,t1.  new\_date) as diff from (select cuid,os,soft\_version,every\_day,from\_unixtime(unix\_timestamp(every\_day,"yyyyMMdd"),"yyyy-MM-dd") as new\_date from tb\_cuid\_1d) t1 join (select cuid,os,soft\_version,every\_day,from\_unixtime(unix\_timestamp(every\_day,"yyyyMMdd"),"yyyy-MM-dd") as new\_date from tb\_cuid\_1d) t2 on t1.cuid = t2.cuid where t2.every\_day >= t1.every\_day) t3 where t3.every\_day = "20200401" group by t3.every\_day,t3.diff;    select t3.new\_dt,t3.diff,count(distinct t3.cuid) as cnt from (  select  t1.cuid,  t1.new\_dt,  datediff(t2.new\_dt,t1.new\_dt) as diff  from  (select cuid,os,soft\_version,every\_day,from\_unixtime(unix\_timestamp(every\_day,'yyyyMMdd'),'yyyy-MM-dd') as new\_dt from test6) as t1  join  (select cuid,os,soft\_version,every\_day,from\_unixtime(unix\_timestamp(every\_day,'yyyyMMdd'),'yyyy-MM-dd') as new\_dt from test6) as t2  on t1.cuid = t2.cuid  where t1.new\_dt<=t2.new\_dt  ) t3  where t3.new\_dt='2020-04-01'  group by t3.new\_dt,t3.diff |

## 解析tb\_cuid\_1d表中ext中所有的"type"对应的值

|  |
| --- |
| select cuid,os,soft\_version,every\_day,get\_json\_object(v.jstr,"$.type") as tp from tb\_cuid\_1d lateral view explode(ext) v as jstr;    select  get\_json\_object(jstr,"$.id") as id ,  get\_json\_object(jstr,"$.type") as tp  from test6  lateral view explode(split(ext,'#')) v as jstr |

## 统计tb\_cuid\_1d表中，20200401号不同平台 、 版本下的uv、 pv

|  |
| --- |
| select os,soft\_version,count(cuid) as pv,count(distinct cuid) as uv from tb\_cuid\_1d where every\_day="20200401" group by os,soft\_version; |

## 基于以上统计结果，如果查看当天总的uv，pv是否能直接加和，为什么？

|  |
| --- |
| pv是可以相加的，uv不能相加，因为如果相同用户使用不同平台不同版本登录时，uv的数据不一致。 |

## 一条sql统计当天不同平台、版本下的uv、pv ， 以及整体的uv， pv

|  |
| --- |
| select distinct every\_day,os,soft\_version,pv,uv,total\_pv,total\_uv from (select os,soft\_version,every\_day,count(cuid) over(partition by os,s  oft\_version) as pv ,size(collect\_set(cuid) over(partition by os,soft\_version)) as uv,count(cuid) over(partition by every\_day) as total\_pv, size(collect\_set(cuid) over(partition by every\_day)) as total\_uv from tb\_cuid\_1d) t ;    select distinct every\_day,os,soft\_version ,pv,uv,total\_pv,total\_uv from (select every\_day,os,soft\_version,count(cuid) over (partition by every\_day,os,soft\_version) as pv ,size(collect\_set(cuid) over (partition by every\_day,os,soft\_version)) as uv ,count(cuid) over(partition by every\_day) as total\_pv,size(collect\_set(cuid) over (partition by every\_day)) as total\_uv from test6) ttt; |
