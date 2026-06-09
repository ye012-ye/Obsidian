hdfs 命令使用时可以使用“hadoop fs + cmd”或者“hdfs dfs + cmd” 这种方式，其中cmd常用命令如下：

- -ls : 查看HDFS中某个目录下的文件信息。
- -mkdir:在HDFS中创建目录，还可跟上-p来创建多级目录。
- -moveFromLocal:将文件从本地剪切到HDFS目录中。
- -cat:显示HDFS文件内容。
- -appendToFile：追加一个文件到已经存在的文件末尾。
- -chmod:给文件赋值权限，文件系统中的用法一样。
- -copyFromLocal：从本地文件系统中拷贝文件到HDFS路径去
- -copyToLocal:从HDFS拷贝文件或者目录到本地。
- -cp : 从HDFS的一个路径拷贝到HDFS的另一个路径。
- -mv:在HDFS目录中移动文件，将文件移动到某个HDFS目录中。
- -get：等同于copyToLocal，将文件从HDFS中下载文件到本地
- -getmerge：合并下载多个文件，比如HDFS的目录 /hello4下有多个文件:a.txt,b.txt,c.txt...,可以通过此命令，将数据合并下载到本地某个目录。
- -put：等同于copyFromLocal，将本地文件复制上传到HDFS中。
- -tail：显示一个文件最后1kb数据到控制台。
- -rm：删除文件或文件夹。可以加上 -r来递归删除目录下的所有数据。.
- -rmr：删除空目录，目录必须是空目录才可以。
- -du:统计文件夹的大小信息。
- -setrep：设置HDFS中文件的副本数量。
