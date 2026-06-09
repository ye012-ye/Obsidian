在 HDFS 中可以使用以下命令查看某个文件的前两行内容：

|  |
| --- |
| hdfs dfs -cat <file\_path> | head -n 2 |

参数说明：

- hdfs dfs -cat <file\_path>：显示 HDFS 上指定文件的内容。
- | head -n 2：通过管道命令将输出传递给 head，并只显示前两行。
