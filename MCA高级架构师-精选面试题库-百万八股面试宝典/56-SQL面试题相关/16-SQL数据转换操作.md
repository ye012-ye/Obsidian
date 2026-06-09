表temp两个字段：

|  |  |
| --- | --- |
| **user** | **profile** |
| abc | key1:value,key2:value2 |
| def | key1:value,key2:value2,key3:value3,key4:value4 |
| xyz | Key1:value |

需要转换如下结构：

|  |  |
| --- | --- |
| **user** | **profile\_value** |
| abc | value |
| abc | vlaue2 |
| def | value |
| def | value2 |
| def | value3 |
| def | value4 |
| xyz | value |

data.txt数据:

|  |
| --- |
| abc key1:value,key2:value2  def key1:value,key2:value2,key3:value3,key4:value4  xyz Key1:value |

SQL建表语句：

|  |
| --- |
| create table temp (usr string,profile string) row format delimited fields terminated by '\t'; |

SQL：

|  |
| --- |
| select `user`,key,value from temp lateral view explode(str\_to\_map(profile,",",":")) mp as key,value |
