有文件a.txt，内容如下:

|  |
| --- |
| zhangsan  lisi  zhangsan  wangwu  lisi  maliu |

使用shell命令实现文件内容去重。

shell命令如下：

|  |
| --- |
| sort -u a.txt |

命令解释：

- sort：用于对文本文件的行进行排序的命令，默认情况下，sort 按照字符的字典顺序对行进行排序。
- -u：sort命令的选项，表示在排序的同时去除重复的行，对于相同的行，只保留一行，其他重复的行将被删除。
