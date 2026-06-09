要求：脚本实现将指定目录下的所有文件中的$HADOOP\_HOME$替换成/home/hadoop。

假设在/root/test目录下有多个文件中包含 $HADOOP\_HOME$ 内容：

|  |
| --- |
| echo "zs ls ww \$HADOOP\_HOME\$" > /root/test/a.sh    echo "hello \$HADOOP\_HOME\$  world \$HADOOP\_HOME\$" > /root/test/b.sh |

替换脚本replace\_hadoop\_home.sh内容如下：

|  |
| --- |
| find "/root/test" -type f | while read -r file;do  sed -i 's/\$HADOOP\_HOME\$/\/home\/hadoop/g' "$file"  echo "处理文件 $file 完成"  done |

以上命令解释如下：

- find 命令用于查找目标目录中的文件，“-type f”表示只查找普通文件；
- “| while read -r file; do”表示通过管道将find 命令输出的多个文件进行while遍历；
- “read -r file”逐行读取文件路径并将其存储到变量 file 中，-r表示禁止 read 命令对反斜杠进行特殊处理，确保读取的路径被准确保留。
- “sed -i ...”:文本替换，特殊符号使用反斜杠进行转义，以免被解释为变量。
