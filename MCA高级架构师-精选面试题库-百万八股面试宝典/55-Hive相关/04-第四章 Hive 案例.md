# **4 第四章Hive 案例**

## 4.1 **行列变换**

### **4.1.1 多行转一行**

有如下表及数据，按照需求转换数据。

```plain
#建表语句及插入数据
CREATE TABLE people (
    name STRING,
    category STRING,
    price INT
) row format delimited fields terminated by '\t';

INSERT INTO people  VALUES
    ('zhangsan', 'A', 1),
    ('zhangsan', 'B', 2),
    ('zhangsan', 'C', 3),
    ('lisi', 'A', 4),
    ('lisi', 'C', 5),
    ('zhangsan', 'D', 6),
    ('lisi', 'B', 7),
('wangwu', 'C', 8);

#查询数据
+--------------+------------------+---------------+
| people.name  | people.category  | people.price  |
+--------------+------------------+---------------+
| zhangsan     | A                | 1             |
| zhangsan     | B                | 2             |
| zhangsan     | C                | 3             |
| lisi         | A                | 4             |
| lisi         | C                | 5             |
| zhangsan     | D                | 6             |
| lisi         | B                | 7             |
| wangwu       | C                | 8             |
+--------------+------------------+---------------+
```

将以上数据转换成如下格式：

```plain
+-----------+----------+--------------+
|   name    |   str    | total_price  |
+-----------+----------+--------------+
| lisi      | A,C,B    | 16           |
| wangwu    | C        | 8            |
| zhangsan  | A,B,C,D  | 12           |
+-----------+----------+--------------+
```

实现以上需求SQL语句如下：

```plain
#sql
select 
  name,concat_ws(",",collect_list(category)) as str,sum(price) as total_price
from people
group by name
```

### **4.1.2 行转列**

有如下表及数据：

```plain
#建表语句及插入数据
CREATE TABLE testdb.student_scores (
    name STRING,
    subject STRING,
    score INT
) row format delimited fields terminated by '\t';

insert into student_scores values 
 ('zhangsan', 'math', 85),
 ('zhangsan', 'english', 78),
 ('lisi', 'math', 90),
 ('lisi', 'english', 82),
 ('lisi', 'science', 88),
 ('wangwu', 'math', 75),
 ('wangwu', 'science', 80);
 
#查询表中数据
select * from student_scores;
+----------------------+-------------------------+-----------------------+
| student_scores.name  | student_scores.subject  | student_scores.score  |
+----------------------+-------------------------+-----------------------+
| zhangsan             | math                    | 85                    |
| zhangsan             | english                 | 78                    |
| lisi                 | math                    | 90                    |
| lisi                 | english                 | 82                    |
| lisi                 | science                 | 88                    |
| wangwu               | math                    | 75                    |
| wangwu               | science                 | 80                    |
+----------------------+-------------------------+-----------------------+
```

将以上数据转换成如下格式，进行行转列：

```plain
+-----------+-------+----------+----------+
|   name    | math  | english  | science  |
+-----------+-------+----------+----------+
| lisi      | 90    | 82       | 88       |
| wangwu    | 75    | 0        | 80       |
| zhangsan  | 85    | 78       | 0        |
+-----------+-------+----------+----------+
```

有如下两种方式实现：

```plain
#实现方式1
select
 name,
 sum(case when subject = 'math' then score else 0 end) as math,
 sum(case when subject = 'english' then score else 0 end) as english,
 sum(case when subject = 'science' then score else 0 end) as science
from student_scores
group by name;

#实现方式2
with temp as (
 select name ,str_to_map(concat_ws(",",collect_list(concat(subject,":",score))),",",":") as mp
 from student_scores
 group by name
)
select 
  name,
  nvl(mp['math'],0) as math,
  nvl(mp['english'],0) as english,
  nvl(mp['science'],0) as science
from temp;

#结果
+-----------+-------+----------+----------+
|   name    | math  | english  | science  |
+-----------+-------+----------+----------+
| lisi      | 90    | 82       | 88       |
| wangwu    | 75    | 0        | 80       |
| zhangsan  | 85    | 78       | 0        |
+-----------+-------+----------+----------+
```

### **4.1.3 列转行**

有如下表及数据：

```plain
#建表及插入数据
create table student_scores2(
 name string,
 math int,
 english int,
 science int
) row format delimited fields terminated by '\t';

insert into student_scores2 values
("lisi",90,82,88),("wangwu",75,null,80),("zhangsan",85,78,null);

#查询表数据
select * from student_scores2;
+-----------------------+------------------------+--------------------------+--------------------------+
| student_scores2.name  | student_scores2.math  | student_scores2.english  | student_scores2.science  |
+-----------------------+------------------------+--------------------------+--------------------------+
| lisi                  | 90                     | 82                       | 88                       |
| wangwu                | 75                     | NULL                     | 80                       |
| zhangsan              | 85                     | 78                       | NULL                     |
+-----------------------+------------------------+--------------------------+--------------------------+
```

将以上数据转换成如下格式：

```plain
+----------------------+-------------------------+-----------------------+
| student_scores.name  | student_scores.subject  | student_scores.score  |
+----------------------+-------------------------+-----------------------+
| zhangsan             | math                    | 85                    |
| zhangsan             | english                 | 78                    |
| lisi                 | math                    | 90                    |
| lisi                 | english                 | 82                    |
| lisi                 | science                 | 88                    |
| wangwu               | math                    | 75                    |
| wangwu               | science                 | 80                    |
+----------------------+-------------------------+-----------------------+
```

实现以上列转行操作有两种方式，如下：

```plain
#第一种实现方式
select
  name,
  subject,
  score   
from (select 
  name,"math" as subject,math as score
from student_scores2
union
select 
  name,"english" as subject,english as score
from student_scores2
union
select 
  name,"science" as subject,science as score
from student_scores2) t
where score is not null;

#第二种实现方式
with temp as (
 select name,map("math",math,"english",english,"science",science) as mp
 from student_scores2 
)
select name ,k as subject,v as score from temp lateral view explode(mp) v as k,v
where v is not null;

#结果
+-----------+----------+--------+
|   name    | subject  | score  |
+-----------+----------+--------+
| lisi      | english  | 82     |
| lisi      | math     | 90     |
| lisi      | science  | 88     |
| wangwu    | math     | 75     |
| wangwu    | science  | 80     |
| zhangsan  | english  | 78     |
| zhangsan  | math     | 85     |
+-----------+----------+--------+
```

## 4.2 **Json数据处理**

### **4.2.1 简单json处理**

有如下json数据，建表并加载数据，解析json中各个属性。

```plain
#数据
{"user_id": "user1", "action_type": "login", "dt": "1970-01-02"}
{"user_id": "user2", "action_type": "logout", "dt": "1970-01-03"}
{"user_id": "user3", "action_type": "wait", "dt": "1970-01-04"}

#建表语句
create table json_tbl1 (
    log_json string
)
row format delimited fields terminated by '\t';

#加载数据
load data inpath '/data.txt' into table json_tbl1;

#查表中数据
select * from json_tbl1;
+----------------------------------------------------+
|                 json_tbl1.log_json                 |
+----------------------------------------------------+
| {"user_id": "user1", "action_type": "login", "dt": "1970-01-02"} |
| {"user_id": "user2", "action_type": "logout", "dt": "1970-01-03"} |
| {"user_id": "user3", "action_type": "wait", "dt": "1970-01-04"} |
+----------------------------------------------------+

#获取json属性
SELECT
    get_json_object(log_json, '$.user_id') AS user_id,
    get_json_object(log_json, '$.action_type') AS action_type,
    get_json_object(log_json, '$.dt') AS dt
FROM json_tbl1;

#结果
+----------+--------------+-------------+
| user_id  | action_type  |     dt      |
+----------+--------------+-------------+
| user1    | login        | 1970-01-02  |
| user2    | logout       | 1970-01-03  |
| user3    | wait         | 1970-01-04  |
+----------+--------------+-------------+
```

### **4.2.2 嵌套json处理**

有如下嵌套json数据，建表加载数据，并获取json中属性值，包括嵌套json中属性的值。

```plain
#数据
{"name":"zhangsan","score":100,"infos":{"age":20,"gender":"man"}}
{"name":"lisi","score":70,"infos":{"age":21,"gender":"femal"}}
{"name":"wangwu","score":80,"infos":{"age":23,"gender":"man"}}
{"name":"maliu","score":50,"infos":{"age":16,"gender":"femal"}}
{"name":"tianqi","score":90,"infos":{"age":19,"gender":"man"}}

#建表语句
create table json_tbl2 (
    json_string string
)
row format delimited fields terminated by '\t';

#加载数据
load data inpath '/data.txt' into table json_tbl2;

#查看表中数据
select * from json_tbl2;
+----------------------------------------------------+
|               json_tbl2.json_string                |
+----------------------------------------------------+
| {"name":"zhangsan","score":100,"infos":{"age":20,"gender":"man"}} |
| {"name":"lisi","score":70,"infos":{"age":21,"gender":"femal"}} |
| {"name":"wangwu","score":80,"infos":{"age":23,"gender":"man"}} |
| {"name":"maliu","score":50,"infos":{"age":16,"gender":"femal"}} |
| {"name":"tianqi","score":90,"infos":{"age":19,"gender":"man"}} |
+----------------------------------------------------+

#获取各个属性的值
SELECT
  get_json_object(json_string, '$.name') AS name,
  get_json_object(json_string, '$.score') AS score,
  get_json_object(json_string, '$.infos.age') AS age,
  get_json_object(json_string, '$.infos.gender') AS gender
FROM json_tbl2;

#结果
+-----------+--------+------+---------+
|   name    | score  | age  | gender  |
+-----------+--------+------+---------+
| zhangsan  | 100    | 20   | man     |
| lisi      | 70     | 21   | femal   |
| wangwu    | 80     | 23   | man     |
| maliu     | 50     | 16   | femal   |
| tianqi    | 90     | 19   | man     |
+-----------+--------+------+---------+
```

### **4.2.3 jsonArray处理**

有如下jsonArray字符串数据，建表加载数据并获取属性数据。

```plain
#数据
{"name":"zhangsan","age":18,"scores":[{"yuwen":98,"shuxue":90,"yingyu":100},{"dili":98,"shengwu":78,"huaxue":100}]}
{"name":"lisi","age":19,"scores":[{"yuwen":58,"shuxue":50,"yingyu":78},{"dili":56,"shengwu":76,"huaxue":13}]}
{"name":"wangwu","age":17,"scores":[{"yuwen":18,"shuxue":90,"yingyu":45},{"dili":76,"shengwu":42,"huaxue":45}]}
{"name":"zhaoliu","age":20,"scores":[{"yuwen":68,"shuxue":23,"yingyu":63},{"dili":23,"shengwu":45,"huaxue":87}]}
{"name":"tianqi","age":22,"scores":[{"yuwen":88,"shuxue":91,"yingyu":41},{"dili":56,"shengwu":79,"huaxue":45}]}

#建表语句及加载数据
create table json_tbl3 (
    json_string string
)
row format delimited fields terminated by '\t';

#查询数据
select * from json_tbl3;
+----------------------------------------------------+
|               json_tbl3.json_string                |
+----------------------------------------------------+
| {"name":"zhangsan","age":18,"scores":[{"yuwen":98,"shuxue":90,"yingyu":100},{"dili":98,"shengwu":78,"huaxue":100}]} |
| {"name":"lisi","age":19,"scores":[{"yuwen":58,"shuxue":50,"yingyu":78},{"dili":56,"shengwu":76,"huaxue":13}]} |
| {"name":"wangwu","age":17,"scores":[{"yuwen":18,"shuxue":90,"yingyu":45},{"dili":76,"shengwu":42,"huaxue":45}]} |
| {"name":"zhaoliu","age":20,"scores":[{"yuwen":68,"shuxue":23,"yingyu":63},{"dili":23,"shengwu":45,"huaxue":87}]} |
| {"name":"tianqi","age":22,"scores":[{"yuwen":88,"shuxue":91,"yingyu":41},{"dili":56,"shengwu":79,"huaxue":45}]} |
+----------------------------------------------------+

#sql
with temp as (
select 
  get_json_object(json_string, '$.name') AS name,
  get_json_object(json_string, '$.age') AS age,
  substr(get_json_object(json_string, '$.scores'),2,length(get_json_object(json_string, '$.scores'))-2) AS scores 
from json_tbl3
)
select 
  name,
  age,
  get_json_object(scores_json,"$.yuwen") as yuwen,
  get_json_object(scores_json, '$.shuxue') as shuxue,
  get_json_object(scores_json, '$.yingyu') as yingyu,
  get_json_object(scores_json, '$.dili') as dili,
  get_json_object(scores_json, '$.shengwu') as shengwu,
  get_json_object(scores_json, '$.huaxue') as huaxue
from temp lateral view explode(split(replace(scores,"},{","}-{"),"-")) v AS scores_json;

#结果
+--------+---+-----+------+------+----+-------+------+
|    name|age|yuwen|shuxue|yingyu|dili|shengwu|huaxue|
+--------+---+-----+------+------+----+-------+------+
|zhangsan| 18|   98|    90|   100|null|   null|  null|
|zhangsan| 18| null|  null|  null|  98|     78|   100|
|    lisi| 19|   58|    50|    78|null|   null|  null|
|    lisi| 19| null|  null|  null|  56|     76|    13|
|  wangwu| 17|   18|    90|    45|null|   null|  null|
|  wangwu| 17| null|  null|  null|  76|     42|    45|
| zhaoliu| 20|   68|    23|    63|null|   null|  null|
| zhaoliu| 20| null|  null|  null|  23|     45|    87|
|  tianqi| 22|   88|    91|    41|null|   null|  null|
|  tianqi| 22| null|  null|  null|  56|     79|    45|
+--------+---+-----+------+------+----+-------+------+
```

**注意：以上substr(string A, int start, int len)函数传入的第二个参数为截取字符串的长度。**

## 4.3 **时间转换**

### **4.3.1 案例一**

有如下表和数据，按要求转换数据。

```plain
#建表语句及数据
create table my_order (
    order_id int comment '订单id',
    customer_id int comment '用户id',
    order_created_time string comment '订单创建时间',
    order_shipped_time string comment '订单发货时间',
    order_delivered_time string comment '订单交付时间'
)
row format delimited fields terminated by ',';

insert into table my_order values
(1, 101, '2024-07-01 10:15:30', '2024-07-02 12:00:00', '2024-07-04 18:30:00'),
(2, 102, '2024-07-01 11:20:45', '2024-07-03 14:10:00', '2024-07-05 20:45:00'),
(3, 103, '2024-07-02 09:10:00', '2024-07-03 15:00:00', '2024-07-06 10:00:00'),
(4, 104, '2024-07-02 14:30:00', '2024-07-03 18:00:00', '2024-07-07 12:00:00');

#查询表中数据
select * from my_order;
+--------------------+-----------------------+------------------------------+------------------------------+--------------------------------+
| my_order.order_id  | my_order.customer_id  | my_order.order_created_time  | my_order.order_shipped_time  | my_order.order_delivered_time  |
+--------------------+-----------------------+------------------------------+------------------------------+--------------------------------+
| 1                  | 101                   | 2024-07-01 10:15:30          | 2024-07-02 12:00:00          | 2024-07-04 18:30:00            |
| 2                  | 102                   | 2024-07-01 11:20:45          | 2024-07-03 14:10:00          | 2024-07-05 20:45:00            |
| 3                  | 103                   | 2024-07-02 09:10:00          | 2024-07-03 15:00:00          | 2024-07-06 10:00:00            |
| 4                  | 104                   | 2024-07-02 14:30:00          | 2024-07-03 18:00:00          | 2024-07-07 12:00:00            |
+--------------------+-----------------------+------------------------------+------------------------------+--------------------------------+
```

需求：统计每个订单创建日期(yyyy/MM/dd）及运输总时间（小时）。

```plain
#sql实现
select 
 order_id,
 customer_id,
 from_unixtime(unix_timestamp( order_created_time),'yyyy/MM/dd') as  create_dt,
 round((unix_timestamp(order_delivered_time) - unix_timestamp(order_shipped_time))/3600,1) AS time_to_ship_hours
from my_order

#结果
+-----------+--------------+-------------+---------------------+
| order_id  | customer_id  |  create_dt  | time_to_ship_hours  |
+-----------+--------------+-------------+---------------------+
| 1         | 101          | 2024/07/01  | 54.5                |
| 2         | 102          | 2024/07/01  | 54.6                |
| 3         | 103          | 2024/07/02  | 67.0                |
| 4         | 104          | 2024/07/02  | 90.0                |
+-----------+--------------+-------------+---------------------+
```

### **4.3.2 案例二**

有如下用户注册和用户活跃数据，建表将数据加载到表中，按照需求进行指标统计。

```plain
#用户注册数据
uid1,20240601
uid2,20240601
uid3,20240601
uid4,20240602
uid5,20240602
uid6,20240603
uid7,20240603
uid8,20240604
uid9,20240604

#建表及加载数据
create table users (
    user_id string,
    regist_dt string
)
row format delimited fields terminated by ',';

load data inpath '/data.txt' into table users;

#用户活跃数据
uid1,20240601
uid2,20240601
uid3,20240601
uid1,20240602
uid2,20240602
uid3,20240602
uid4,20240602
uid5,20240602
uid1,20240603
uid2,20240603
uid3,20240603
uid4,20240603
uid5,20240603
uid6,20240603
uid7,20240603
uid1,20240604
uid2,20240604
uid3,20240604
uid4,20240604
uid5,20240604
uid6,20240604
uid7,20240604
uid8,20240604
uid9,20240604
uid1,20240605
uid2,20240605
uid3,20240605
uid4,20240606
uid4,20240609
uid4,20240611
uid4,20240613
uid5,20240606
uid5,20240609
uid5,20240611
uid5,20240615
uid5,20240617
uid5,20240619
uid6,20240606
uid6,20240610
uid6,20240611
uid6,20240613
uid6,20240614
uid7,20240607
uid8,20240607
uid9,20240607
uid1,20240608
uid1,20240611
uid3,20240608
uid3,20240610

#建表及加载数据
create table user_activity (
    user_id string,
    activity_dt string
)
row format delimited fields terminated by ',';

load data inpath '/data.txt' into table user_activity;
```

统计每个注册日往后的1日~7日的用户留存率。

```plain
#sql实现
set hive.auto.convert.join=false;
with temp as (
select 
  a.user_id,a.regist_dt,b.activity_dt,
  from_unixtime(unix_timestamp(a.regist_dt,"yyyyMMdd"),"yyyy-MM-dd") as format_regist_dt,
  datediff(from_unixtime(unix_timestamp(b.activity_dt,"yyyyMMdd"),"yyyy-MM-dd"),from_unixtime(unix_timestamp(a.regist_dt,"yyyyMMdd"),"yyyy-MM-dd")) as diff 
from users a join user_activity b on a.user_id = b.user_id 
where b.activity_dt >a.regist_dt 
)
select format_regist_dt,diff,count(*) as cnt from temp where diff <=7 group by format_regist_dt,diff ;

#结果
+-------------------+-------+------+
| format_regist_dt  | diff  | cnt  |
+-------------------+-------+------+
| 2024-06-01        | 1     | 3    |
| 2024-06-01        | 2     | 3    |
| 2024-06-01        | 3     | 3    |
| 2024-06-01        | 4     | 3    |
| 2024-06-01        | 7     | 2    |
| 2024-06-02        | 1     | 2    |
| 2024-06-02        | 2     | 2    |
| 2024-06-02        | 4     | 2    |
| 2024-06-02        | 7     | 2    |
| 2024-06-03        | 1     | 2    |
| 2024-06-03        | 3     | 1    |
| 2024-06-03        | 4     | 1    |
| 2024-06-03        | 7     | 1    |
| 2024-06-04        | 3     | 2    |
+-------------------+-------+------+
```

## 4.4 **Hive实现循环**

有如下用户访问网站数据，在hive中创建表并插入数据，实现相应需求。

```plain
#建表及插入数据
CREATE TABLE testdb.user_logs (
    user_id INT,
    start_time string,
    end_time string
) row format delimited fields terminated by '\t';

INSERT INTO user_logs  VALUES 
    (1, '2023-07-01', '2023-07-05'),
    (2, '2023-07-10', '2023-07-20');
```

现在需要获取用户在天内的访问记录，即得到如下结果：

```plain
+----------+-------------+-------------+-------------+
| user_id  | start_time  |  end_time   |   new_dt    |
+----------+-------------+-------------+-------------+
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-01  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-02  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-03  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-04  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-05  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-10  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-11  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-12  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-13  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-14  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-15  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-16  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-17  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-18  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-19  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-20  |
+----------+-------------+-------------+-------------+
```

以上需求实现Hive中一条数据按照一定规则生成多条数据，sql实现如下：

```plain
#sql
SELECT 
 user_id,
 start_time,
 end_time,
 date_add(start_time,pos) as new_dt
FROM user_logs
LATERAL VIEW posexplode(split(space(day(end_time)-day(start_time))," ")) pe AS pos, val

#结果
+----------+-------------+-------------+-------------+
| user_id  | start_time  |  end_time   |   new_dt    |
+----------+-------------+-------------+-------------+
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-01  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-02  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-03  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-04  |
| 1        | 2023-07-01  | 2023-07-05  | 2023-07-05  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-10  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-11  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-12  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-13  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-14  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-15  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-16  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-17  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-18  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-19  |
| 2        | 2023-07-10  | 2023-07-20  | 2023-07-20  |
+----------+-------------+-------------+-------------+
```

## 4.5 **窗口函数使用**

### **4.5.1 案例一**

有如下员工工资数据，建表并将数据加载到表中分析相应需求。

```plain
#数据
1,张三,技术部,20000
2,李四,技术部,25000
3,王五,技术部,25000
4,赵六,技术部,22000
5,陈七,技术部,23000
6,周八,技术部,21000
7,孙九,市场部,18000
8,钱十,市场部,22000
9,吴十一,市场部,22000
10,郑十二,市场部,20000
11,王十三,市场部,19000
12,冯十四,市场部,17000
13,朱十五,财务部,19000
14,何十六,财务部,20000
15,黄十七,财务部,21000
16,刘十八,财务部,18000
17,杨十九,财务部,17500
18,萧二十,财务部,18500

#创建表
create table salary_info(
 id int,
 name string,
 dept_name string,
 salary double
)row format delimited fields terminated by ',';

#加载数据
load data inpath '/data.txt' into table salary_info;
```

需求:统计每个部门中工资最高的前3名员工，以及每位员工工资占部门总工资的比例，结果保留4位小数。

```plain
#sql实现
WITH temp AS (
    SELECT 
        id, name, dept_name, salary,
        DENSE_RANK() OVER(PARTITION BY dept_name ORDER BY salary DESC) as rank,
        ROUND(salary / SUM(salary) OVER (PARTITION BY dept_name), 4) as rate
    FROM 
        salary_info
)
SELECT 
    id, name, dept_name, salary, rank, rate
FROM temp
WHERE rank <= 3
ORDER BY dept_name,rank ;

#结果
+-----+-------+------------+----------+-------+---------+
| id  | name  | dept_name  |  salary  | rank  |  rate   |
+-----+-------+------------+----------+-------+---------+
| 9   | 吴十一   | 市场部        | 22000.0  | 1     | 0.1864  |
| 8   | 钱十    | 市场部        | 22000.0  | 1     | 0.1864  |
| 10  | 郑十二   | 市场部        | 20000.0  | 2     | 0.1695  |
| 11  | 王十三   | 市场部        | 19000.0  | 3     | 0.161   |
| 2   | 李四    | 技术部        | 25000.0  | 1     | 0.1838  |
| 3   | 王五    | 技术部        | 25000.0  | 1     | 0.1838  |
| 5   | 陈七    | 技术部        | 23000.0  | 2     | 0.1691  |
| 4   | 赵六    | 技术部        | 22000.0  | 3     | 0.1618  |
| 15  | 黄十七   | 财务部        | 21000.0  | 1     | 0.1842  |
| 14  | 何十六   | 财务部        | 20000.0  | 2     | 0.1754  |
| 13  | 朱十五   | 财务部        | 19000.0  | 3     | 0.1667  |
+-----+-------+------------+----------+-------+---------+
```

### **4.5.2 案例二**

有如下数据，三列分别为服务器ID、记录时间、服务器状态，建表并将数据加载到表中，按照要求统计指标。

```plain
#数据
server1,2025-01-01 00:00:00,运行中
server1,2025-01-01 01:00:00,运行中
server1,2025-01-01 02:00:00,停止
server1,2025-01-01 03:00:00,维护中
server2,2025-01-01 00:00:00,运行中
server2,2025-01-01 01:00:00,维护中
server2,2025-01-01 02:00:00,维护中
server2,2025-01-01 03:00:00,运行中
server3,2025-01-01 00:00:00,停止
server3,2025-01-01 01:00:00,停止
server3,2025-01-01 02:00:00,运行中
server3,2025-01-01 03:00:00,维护中

#建表并加载数据
CREATE TABLE server_status (
    server_id STRING,
    record_time STRING,
    server_status STRING
)
row format delimited fields terminated by ',';

load data inpath '/data.txt' into table server_status;
```

根据以上表数据，统计每个服务器状态相比于上一条数据变化的数据条目。

```plain
#sql
with temp as (
 select server_id,record_time,server_status,
 lag(server_status,1) over(partition by server_id order by record_time) as flag 
 from server_status
)
select server_id,record_time,server_status 
from temp 
where flag is not null and server_status != flag;

#结果
+------------+----------------------+----------------+
| server_id  |     record_time      | server_status  |
+------------+----------------------+----------------+
| server1    | 2025-01-01 02:00:00  | 停止             |
| server1    | 2025-01-01 03:00:00  | 维护中            |
| server2    | 2025-01-01 01:00:00  | 维护中            |
| server2    | 2025-01-01 03:00:00  | 运行中            |
| server3    | 2025-01-01 02:00:00  | 运行中            |
| server3    | 2025-01-01 03:00:00  | 维护中            |
+------------+----------------------+----------------+
```

### **4.5.3 案例三**

有如下vpn日志数据，数据中只有一天的用户数据，描述的是用户登录/登出网站信息，根据此数据创建表并进行数据分析。

```plain
#数据
a,2025-04-07T00:12:02,logout
a,2025-04-07T00:25:36,login
a,2025-04-07T01:45:36,logout
a,2025-04-07T03:15:23,login
a,2025-04-07T04:25:57,logout
a,2025-04-07T05:04:36,login
a,2025-04-07T07:08:32,logout
a,2025-04-07T08:09:00,login
a,2025-04-07T12:15:43,logout
a,2025-04-07T16:35:18,login
a,2025-04-07T19:48:36,logout
a,2025-04-07T21:25:36,login
a,2025-04-07T21:35:36,logout
a,2025-04-07T21:40:36,login
a,2025-04-07T22:15:36,logout
a,2025-04-07T23:17:21,login
b,2025-04-07T00:25:36,login
b,2025-04-07T01:45:36,logout
b,2025-04-07T03:15:23,login
b,2025-04-07T04:25:57,logout
b,2025-04-07T05:04:36,login
b,2025-04-07T07:08:32,logout
b,2025-04-07T10:08:32,login
b,2025-04-07T12:15:43,logout
b,2025-04-07T16:35:18,login
b,2025-04-07T19:48:36,logout
b,2025-04-07T21:25:36,login
b,2025-04-07T21:35:36,logout
b,2025-04-07T21:50:36,login
b,2025-04-07T22:15:36,logout
b,2025-04-07T23:17:21,login

#建表
create table vpn_log(
 user_name string,
 dt string,
 state string
) row format delimited fields terminated by ',';

#加载数据
load data inpath '/data.txt' into table vpn_log;
```

需求如下：

- 统计该天24小时中，每小时在线的用户数。

- 统计该天每个用户在线的总时长（分钟）、在线次数、最大在线时长（分钟）。（如果用户一天开始时logout记录，则认为该用户零点登录login，如果一天结束时为login记录，则认为他24点登出）

对于第一个需求，观察数据可以发现数据中用户有登录/登出操作，并且该天中用户最开始一条数据可能是登出或者最后一条数据为登录，需要按照相同用户进行错位匹配组织出来缺失的登录/登出数据，然后针对跨小时的每条登录登出数据进行膨胀处理，最后按照小时统计每小时中相同用户数有哪些。

```plain
#统计该天24小时中，每小时在线的用户数
with temp1 as (
-- 处理时间，每行按照user_name分组、时间排序，打标签rank
select
   user_name,replace(dt,"T"," ") as dt,state,
   row_number() over (partition by user_name order by dt) as rank 
from vpn_log
) ,
temp2 as (
--错位相关联，组织数据
select 
 case when a.user_name is null then b.user_name else a.user_name end user_name1,
 case when a.dt is null then concat(split(b.dt," ")[0],' 00:00:00') else a.dt end dt1,
 case when a.state is null then 'login' else a.state end state1,
 a.rank as rank1,
 case when b.user_name is null then a.user_name else b.user_name end user_name2,
 case when b.dt is null then concat(split(a.dt," ")[0],' 23:59:59') else b.dt end dt2,
 case when b.state is null then 'logout' else b.state end state2,
 b.rank 
from temp1 a full join temp1 b 
on a.user_name = b.user_name and a.rank = b.rank-1
),
temp3 as (
 --查询组织好的login/logout数据
 select 
  user_name1 as user_name,
  dt1 as login_dt,
  state1 as login_state,
  dt2 as logout_dt,
  state2 as logout_state
 from temp2
 where state1 != 'logout' and state2 !='login'
)

select 
 t.hour_dur,count(distinct user_name) as cnt
from (
select 
 user_name,login_dt,login_state,logout_dt,logout_state,(hour(login_dt)+pos) as hour_dur 
from temp3 lateral view posexplode(split(space(hour(logout_dt)-hour(login_dt))," ")) pe as pos ,val) as t
group by t.hour_dur;

#结果
+-------------+------+
| t.hour_dur  | cnt  |
+-------------+------+
| 0           | 2    |
| 1           | 2    |
| 3           | 2    |
| 4           | 2    |
| 5           | 2    |
| 6           | 2    |
| 7           | 2    |
| 8           | 1    |
| 9           | 1    |
| 10          | 2    |
| 11          | 2    |
| 12          | 2    |
| 16          | 2    |
| 17          | 2    |
| 18          | 2    |
| 19          | 2    |
| 21          | 2    |
| 22          | 2    |
| 23          | 2    |
+-------------+------+
```

对于第二个需求中，直接基于第一个需求统计的temp3结果先统计每次登录/登出对应的在线时长，然后进一步统计每个用户在线的总时长、在线次数、最大在线时长即可。

```plain
#sql
with temp1 as (
-- 处理时间，每行按照user_name分组、时间排序，打标签rank
select
   user_name,replace(dt,"T"," ") as dt,state,
   row_number() over (partition by user_name order by dt) as rank 
from vpn_log
) ,
temp2 as (
--错位相关联，组织数据
select 
 case when a.user_name is null then b.user_name else a.user_name end user_name1,
 case when a.dt is null then concat(split(b.dt," ")[0],' 00:00:00') else a.dt end dt1,
 case when a.state is null then 'login' else a.state end state1,
 a.rank as rank1,
 case when b.user_name is null then a.user_name else b.user_name end user_name2,
 case when b.dt is null then concat(split(a.dt," ")[0],' 23:59:59') else b.dt end dt2,
 case when b.state is null then 'logout' else b.state end state2,
 b.rank 
from temp1 a full join temp1 b 
on a.user_name = b.user_name and a.rank = b.rank-1
),
temp3 as (
 --查询组织好的login/logout数据
 select 
  user_name1 as user_name,
  dt1 as login_dt,
  state1 as login_state,
  dt2 as logout_dt,
  state2 as logout_state
 from temp2
 where state1 != 'logout' and state2 !='login'
)
--统计该天每个用户在线的总时长、在线次数、最大在线时长
select 
  user_name,
  sum(minute_diff) as total_online_minute,
  count(user_name) as online_times,
  max(minute_diff) as max_online_minute 
from (
 select user_name ,login_dt,logout_dt, 
 cast(hour(logout_dt)*60 + minute(logout_dt) + second(logout_dt)/60 as bigint)- cast(hour(login_dt)*60 + minute(login_dt) + second(login_dt)/60 as bigint) as minute_diff 
 from temp3 
) as t 
group by user_name;

#结果
+------------+----------------------+---------------+--------------------+
| user_name  | total_online_minute  | online_times  | max_online_minute  |
+------------+----------------------+---------------+--------------------+
| a          | 812                  | 9             | 246                |
| b          | 671                  | 8             | 193                |
+------------+----------------------+---------------+--------------------+
```

### **4.5.4 案例四**

对user\_activity表中用户活跃数据统计连续3日活跃的用户有哪些。

```plain
#查询user_activity表数据
select * from user_activity order by user_id,activity_dt;
+------------------------+----------------------------+
| user_activity.user_id  | user_activity.activity_dt  |
+------------------------+----------------------------+
| uid1                   | 20240601                   |
| uid1                   | 20240602                   |
| uid1                   | 20240603                   |
| uid1                   | 20240604                   |
| uid1                   | 20240605                   |
| uid1                   | 20240608                   |
| uid1                   | 20240611                   |
| uid2                   | 20240601                   |
| uid2                   | 20240602                   |
| uid2                   | 20240603                   |
| uid2                   | 20240604                   |
| uid2                   | 20240605                   |
| uid3                   | 20240601                   |
| uid3                   | 20240602                   |
| uid3                   | 20240603                   |
| uid3                   | 20240604                   |
| uid3                   | 20240605                   |
| uid3                   | 20240608                   |
| uid3                   | 20240610                   |
| uid4                   | 20240602                   |
| uid4                   | 20240603                   |
| uid4                   | 20240604                   |
| uid4                   | 20240606                   |
| uid4                   | 20240609                   |
| uid4                   | 20240611                   |
| uid4                   | 20240613                   |
| uid5                   | 20240602                   |
| uid5                   | 20240603                   |
| uid5                   | 20240604                   |
| uid5                   | 20240606                   |
| uid5                   | 20240609                   |
| uid5                   | 20240611                   |
| uid5                   | 20240615                   |
| uid5                   | 20240617                   |
| uid5                   | 20240619                   |
| uid6                   | 20240603                   |
| uid6                   | 20240604                   |
| uid6                   | 20240606                   |
| uid6                   | 20240610                   |
| uid6                   | 20240611                   |
| uid6                   | 20240613                   |
| uid6                   | 20240614                   |
| uid7                   | 20240603                   |
| uid7                   | 20240604                   |
| uid7                   | 20240607                   |
| uid8                   | 20240604                   |
| uid8                   | 20240607                   |
| uid9                   | 20240604                   |
| uid9                   | 20240607                   |
+------------------------+----------------------------+
```

sql和结果如下：

```plain
#sql
with temp1 as (select  
  user_id,activity_dt,
  lead(activity_dt,3) over(partition by user_id order by activity_dt) as flag 
from user_activity
),
temp2 as (
select 
  user_id,
  activity_dt,
  datediff(from_unixtime(unix_timestamp(flag,"yyyyMMdd"),"yyyy-MM-dd"),from_unixtime(unix_timestamp(activity_dt,"yyyyMMdd"),"yyyy-MM-dd")) as diff
from temp1 
where flag is not null
)
select distinct user_id from temp2 where diff=3;

#结果
+----------+
| user_id  |
+----------+
| uid1     |
| uid2     |
| uid3     |
+----------+
```

### **4.5.5 案例五**

对user\_activity表中用户活跃数据统计每个用户最大连续活跃的天数是多少？例如：uid1、uid2、uid3最大连续登录天数都为5天。

```plain
#查询user_activity表数据
select * from user_activity order by user_id,activity_dt;
+------------------------+----------------------------+
| user_activity.user_id  | user_activity.activity_dt  |
+------------------------+----------------------------+
| uid1                   | 20240601                   |
| uid1                   | 20240602                   |
| uid1                   | 20240603                   |
| uid1                   | 20240604                   |
| uid1                   | 20240605                   |
| uid1                   | 20240608                   |
| uid1                   | 20240611                   |
| uid2                   | 20240601                   |
| uid2                   | 20240602                   |
| uid2                   | 20240603                   |
| uid2                   | 20240604                   |
| uid2                   | 20240605                   |
| uid3                   | 20240601                   |
| uid3                   | 20240602                   |
| uid3                   | 20240603                   |
| uid3                   | 20240604                   |
| uid3                   | 20240605                   |
| uid3                   | 20240608                   |
| uid3                   | 20240610                   |
| uid4                   | 20240602                   |
| uid4                   | 20240603                   |
| uid4                   | 20240604                   |
| uid4                   | 20240606                   |
| uid4                   | 20240609                   |
| uid4                   | 20240611                   |
| uid4                   | 20240613                   |
| uid5                   | 20240602                   |
| uid5                   | 20240603                   |
| uid5                   | 20240604                   |
| uid5                   | 20240606                   |
| uid5                   | 20240609                   |
| uid5                   | 20240611                   |
| uid5                   | 20240615                   |
| uid5                   | 20240617                   |
| uid5                   | 20240619                   |
| uid6                   | 20240603                   |
| uid6                   | 20240604                   |
| uid6                   | 20240606                   |
| uid6                   | 20240610                   |
| uid6                   | 20240611                   |
| uid6                   | 20240613                   |
| uid6                   | 20240614                   |
| uid7                   | 20240603                   |
| uid7                   | 20240604                   |
| uid7                   | 20240607                   |
| uid8                   | 20240604                   |
| uid8                   | 20240607                   |
| uid9                   | 20240604                   |
| uid9                   | 20240607                   |
+------------------------+----------------------------+
```

sql和结果如下：

```plain
#sql
WITH temp1 AS (
    SELECT
        user_id,
        from_unixtime(unix_timestamp(activity_dt,"yyyyMMdd"),"yyyy-MM-dd") as dt,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_dt) AS rk,
        date_sub(from_unixtime(unix_timestamp(activity_dt,"yyyyMMdd"),"yyyy-MM-dd"),ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY activity_dt)) as flag
    FROM user_activity
),
temp2 AS (
    SELECT
        user_id,
        flag,
        COUNT(*) AS cnt
    FROM temp1
    GROUP BY user_id, flag
)
SELECT
    user_id,
    MAX(cnt) AS max_days 
FROM temp2
GROUP BY user_id;

#结果
+----------+-----------+
| user_id  | max_days  |
+----------+-----------+
| uid1     | 5         |
| uid2     | 5         |
| uid3     | 5         |
| uid4     | 3         |
| uid5     | 3         |
| uid6     | 2         |
| uid7     | 2         |
| uid8     | 1         |
| uid9     | 1         |
+----------+-----------+
```

### **4.5.6 案例六**

假设用户连续两次登录天间隔一天，也看成用户连续登录，对user\_activity表中用户活跃数据统计每个用户最大连续活跃的天数是多少？例如：uid6在20240604登录，然后在20240606又登录，也看成用户连续登录，uid6最大连续登录天数为5天。

sql思路：根据需求，用户如果连续两次登录间隔一天也算连续登录，那么首先通过lag函数将每行数据与其上一行数据进行关联，进行每行数据日期与下行数据日期差值，如果差值小于2，那么连续差值小于2的登录数据就可以看成是连续登录。当然一个用户中可能会出现连续登录几天后，隔了很长时间又出现连续登录，也就是说一个用户中可能有多个连续登录的情况，我们需要找出用户多个登录情况中最大的连续登录天数。

如下uid6 统计上下两行登录天差值可以看到2024-06-03这天连续登录到2024-06-06，连续登录4天，接着从2024-06-10又连续登录到2024-06-14，连续登录了5天，uid6最大连续登录天数为5。

```plain
+----------+--------------+-------------+-------+
| user_id  | activity_dt  |   lead_dt   | diff  |
+----------+--------------+-------------+-------+
| uid6     | 2024-06-03   | 2024-06-03  | 0     |
| uid6     | 2024-06-04   | 2024-06-03  | 1     |
| uid6     | 2024-06-06   | 2024-06-04  | 2     |
| uid6     | 2024-06-10   | 2024-06-06  | 4     |
| uid6     | 2024-06-11   | 2024-06-10  | 1     |
| uid6     | 2024-06-13   | 2024-06-11  | 2     |
| uid6     | 2024-06-14   | 2024-06-13  | 1     |
+----------+--------------+-------------+-------+
```

为了实现统计每个用户多次连续登录天数统计这个需求，我们需要基于以上结果对用户使用diff列处理，如果小于等于2那么赋值为0，否则赋值为1（只要不是连续登录就会出现1），然后按照uid分组，累计每组中从activity\_dt开始到当前行出现1的个数作为flag分组列，得到如下数据：

```plain
+----------+--------------+-------+
| user_id  | activity_dt  | flag  |
+----------+--------------+-------+
| uid6     | 2024-06-03   | 0     |
| uid6     | 2024-06-04   | 0     |
| uid6     | 2024-06-06   | 0     |
| uid6     | 2024-06-10   | 1     |
| uid6     | 2024-06-11   | 1     |
| uid6     | 2024-06-13   | 1     |
| uid6     | 2024-06-14   | 1     |
+----------+--------------+-------+
```

按照user\_id、flag再次分组找出每组内开始连续登录的第一天和最后一天，如下：

```plain
+----------+--------------+--------------+-------------+
| user_id  | activity_dt  | first_value  | last_value  |
+----------+--------------+--------------+-------------+
| uid6     | 2024-06-03   | 2024-06-03   | 2024-06-06  |
| uid6     | 2024-06-04   | 2024-06-03   | 2024-06-06  |
| uid6     | 2024-06-06   | 2024-06-03   | 2024-06-06  |
| uid6     | 2024-06-10   | 2024-06-10   | 2024-06-14  |
| uid6     | 2024-06-11   | 2024-06-10   | 2024-06-14  |
| uid6     | 2024-06-13   | 2024-06-10   | 2024-06-14  |
| uid6     | 2024-06-14   | 2024-06-10   | 2024-06-14  |
+----------+--------------+--------------+-------------+
```

然后再次统计每个user\_id中last\_value和first\_value差值最大的天数作为当前user\_id连续登录最大的天数，这个结果就是将用户间隔一天连续登录也算连续登录的最大天数。

```plain
+----------+-----------+
| user_id  | max_days  |
+----------+-----------+
| uid1     | 5         |
| uid2     | 5         |
| uid3     | 5         |
| uid4     | 5         |
| uid5     | 5         |
| uid6     | 5         |
| uid7     | 2         |
| uid8     | 1         |
| uid9     | 1         |
+----------+-----------+
```

sql如下：

```plain
#最终sql
with temp1 as (
  select 
    user_id,
    from_unixtime(unix_timestamp(activity_dt,"yyyyMMdd"),"yyyy-MM-dd") as activity_dt 
  from user_activity  
  order by user_id ,activity_dt
),temp2 as (
  select 
    user_id,
    activity_dt,
    lag(activity_dt,1,activity_dt) over (partition by user_id order by activity_dt) as lead_dt,
    datediff(activity_dt,lag(activity_dt,1,activity_dt) over (partition by user_id order by activity_dt)) as diff
  from temp1 
),temp3 as (
 select
   user_id,
   activity_dt,
   sum(if(diff<=2,0,1)) over (partition by user_id order by activity_dt ) flag
 from temp2 
),temp4 as (
  select
   user_id,
   activity_dt,
   first_value(activity_dt) over(partition by user_id,flag order by activity_dt) as first_value,
   last_value(activity_dt) over (partition by user_id,flag order by activity_dt rows between current row and unbounded following) as last_value
 from temp3 
)
select 
  user_id,max(datediff(last_value,first_value)+1) as max_days 
from temp4 
group by user_id 

#最终结果：
+----------+-----------+
| user_id  | max_days  |
+----------+-----------+
| uid1     | 5         |
| uid2     | 5         |
| uid3     | 5         |
| uid4     | 5         |
| uid5     | 5         |
| uid6     | 5         |
| uid7     | 2         |
| uid8     | 1         |
| uid9     | 1         |
+----------+-----------+
```

## 4.6 **其他案例**

### **4.6.1 案例一**

有如下销售数据，将数据加载到表sale\_data中。

```plain
#数据
广东,广州市,手机壳,1950
广东,深圳市,数据线,800
江苏,南京市,无线耳机,450
江苏,苏州市,智能体重秤,160
浙江,杭州市,电子书阅读器,500
浙江,宁波市,蓝牙音箱,1300
山东,青岛市,头戴式耳机,1200
山东,烟台市,充电宝,200
河南,郑州市,移动硬盘,1900
河南,洛阳市,键盘,1700
湖北,武汉市,鼠标,1500
湖北,宜昌市,存储卡,50
河北,石家庄市,路由器,180
河北,唐山市,USB集线器,130
辽宁,大连市,游戏鼠标垫,75
辽宁,沈阳市,网络摄像头,50
四川,成都市,显卡,1500
四川,绵阳市,固态硬盘,1400
湖南,长沙市,打印机,800
湖南,衡阳市,墨盒,4500

#sale_data建表语句
CREATE TABLE testdb.sale_data (
    province string,
    city string,
    product string,
    amount int
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';

#加载数据
load data inpath '/data.txt' into table sale_data;
```

编写sql统计如下指标。

1) 统计所有数据中所有商品销售额都没有超过1000元的省份有哪些？

2) 统计所有数据中只要有一个商品销售额超过1000元的省份有哪些？

3) 统计所有数据中所有商品销售额都超过1000元的省份有哪些？

```plain
#统计所有数据中所有商品销售额都没有超过1000元的省份有哪些？
select province,sum(if(amount<1000,0,1)) as flag from sale_data group by province having flag =0;
+-----------+-------+
| province  | flag  |
+-----------+-------+
| 江苏        | 0     |
| 河北        | 0     |
| 辽宁        | 0     |
+-----------+-------+

#统计所有数据中只要有一个商品销售额超过1000元的省份有哪些？
select province,sum(if(amount>1000,1,0)) as flag from sale_data group by province having flag >0;
+-----------+-------+
| province  | flag  |
+-----------+-------+
| 四川        | 2     |
| 山东        | 1     |
| 广东        | 1     |
| 河南        | 2     |
| 浙江        | 1     |
| 湖北        | 1     |
| 湖南        | 1     |
+-----------+-------+

#统计所有数据中所有商品销售额都超过1000元的省份有哪些？
select province,sum(if(amount>1000,0,1)) as flag from sale_data group by province having flag =0;
+-----------+-------+
| province  | flag  |
+-----------+-------+
| 四川       | 0     |
| 河南       | 0     |
+-----------+-------+
```

此外，第三个需求中统计所有数据中所有商品销售额都超过1000元的省份还可以使用开窗函数中的last\_value来实现，sq如下：

```plain
#使用last_value来统计所有数据中所有商品销售额都超过1000元的省份
with temp as (select 
  province,
  last_value(amount) over (partition by province order by amount desc rows between unbounded preceding and unbounded following) as flag 
from sale_data
)
select distinct province from temp where flag >1000;

#结果
+-----------+
| province  |
+-----------+
| 四川        |
| 河南        |
+-----------+
```

### **4.6.2 案例二**

有如下餐饮订单数据，建表并加载数据。统计购买过“麻辣鸡肉”和“香辣牛肉”但没有购买过“甜品”的顾客。

```plain
#数据
1,1001,麻辣鸡肉,2024-07-01
1,1002,香辣牛肉,2024-07-02
2,1003,麻辣鸡肉,2024-07-01
2,1004,甜品,2024-07-03
3,1005,麻辣鸡肉,2024-07-01
3,1006,香辣牛肉,2024-07-04
4,1007,甜品,2024-07-01
4,1008,麻辣鸡肉,2024-07-02
4,1009,香辣牛肉,2024-07-03
5,1010,麻辣鸡肉,2024-07-01
5,1011,香辣牛肉,2024-07-03
5,1012,甜品,2024-07-04
6,1013,麻辣鸡肉,2024-07-01
6,1014,香辣牛肉,2024-07-02

#建表及加载数据
create table user_orders (
    user_id int,
    order_id int,
    product_name string,
    order_date date
)
row format delimited fields terminated by ',';

load data inpath '/data.txt' into table user_orders;

#查询表中数据
select * from user_orders;
+----------------------+-----------------------+---------------------------+-------------------------+
| user_orders.user_id  | user_orders.order_id  | user_orders.product_name  | user_orders.order_date  |
+----------------------+-----------------------+---------------------------+-------------------------+
| 1                    | 1001                  | 麻辣鸡肉                      | 2024-07-01              |
| 1                    | 1002                  | 香辣牛肉                      | 2024-07-02              |
| 2                    | 1003                  | 麻辣鸡肉                      | 2024-07-01              |
| 2                    | 1004                  | 甜品                        | 2024-07-03              |
| 3                    | 1005                  | 麻辣鸡肉                      | 2024-07-01              |
| 3                    | 1006                  | 香辣牛肉                      | 2024-07-04              |
| 4                    | 1007                  | 甜品                        | 2024-07-01              |
| 4                    | 1008                  | 麻辣鸡肉                      | 2024-07-02              |
| 4                    | 1009                  | 香辣牛肉                      | 2024-07-03              |
| 5                    | 1010                  | 麻辣鸡肉                      | 2024-07-01              |
| 5                    | 1011                  | 香辣牛肉                      | 2024-07-03              |
| 5                    | 1012                  | 甜品                        | 2024-07-04              |
| 6                    | 1013                  | 麻辣鸡肉                      | 2024-07-01              |
| 6                    | 1014                  | 香辣牛肉                      | 2024-07-02              |
+----------------------+-----------------------+---------------------------+-------------------------+
```

需求：统计购买过“麻辣鸡肉”和“香辣牛肉”但没有购买过“甜品”的顾客。

```plain
#sql实现
with temp as (
  select 
    user_id,
    collect_set(product_name) as products
  from 
    user_orders
  group by user_id
)
select user_id from temp  
where array_contains(products, '麻辣鸡肉') 
    and array_contains(products, '香辣牛肉') 
and not array_contains(products, '甜品');

#结果
+----------+
| user_id  |
+----------+
| 1        |
| 3        |
| 6        |
+----------+
```
