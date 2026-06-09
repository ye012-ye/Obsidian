# 1 Linux面试题

## 1.1 查找某文件或某文件夹中文件是否包含指定内容

在 Linux 系统中，可以使用 grep 命令来查找文件中是否包含某内容：

|  |
| --- |
| grep [-r] [-n] "要查找的内容" 文件名/文件夹 |

如果查询某个文件夹中的所有文件是否包含某内容，可以使用-r表示递归查找文件夹下所有文件。-n显示文件中包含内容的行号。

以上问题答案：

|  |
| --- |
| #递归查找/root/test目录下所有包含zs内容的文件及对应内容的行数  grep -rn "zs" /root/test/\* |

## 1.2 查找以a开头的文件

可以直接使用命令：

|  |
| --- |
| find / -type f -name "a\*" |

find 是 Linux 中强大的文件查找工具，其基本语法如下：

|  |
| --- |
| find [路径] [选项] |

- 路径：指定查找的目录路径，默认是当前目录 .。
- 选项：

- 文件类型-type，可以指定为f或者d，f表示查找普通文件，d表示查找目录。
- 文件名 -name，跟上表达式精确匹配文件/文件夹，表达式可以是文件/文件夹名称，也可以使用\*指定匹配模式。

例如指定"a\*"，表示匹配a开头的文件/文件夹，使用引号引起来a\*，表示直接将表达式当做字符串模式处理，匹配以a 开头的任意字符文件/文件夹如果使用引号引起表达式表示。

## 1.3 如何替换文件中的某个字符串为指定内容?

可以通过以下三种方式完成替换文件中某个字符串为指定内容,简单替换推荐使用 sed，效率高且常见,复杂替换（如多行处理）可选用 awk 或 perl。

1. **sed命令**

sed 是 Linux 中强大的流编辑工具，可用于文本替换。

|  |
| --- |
| sed -i 's/原字符串/新字符串/g' 文件名 |

**参数说明：**

- -i：直接修改文件内容，建议提前备份文件。
- s/原字符串/新字符串/：表示替换操作，s 为替换命令。第一个 "/"后写要替换的字符串;第二个"/"后写替换后的字符串。
- g：表示全局替换，若不加 g，只替换每行中首次匹配的内容。

举例：替换文件 example.txt 中的所有 foo 为 bar

|  |
| --- |
| #创建文件  vim /root/example.txt  foo  bar  foo  bar  zs  ls    #替换文件 example.txt 中的所有foo为bar  sed 's/foo/bar/g' /root/example.txt |

1. **awk命令**

awk 是linux强大的文本处理工具，可用于复杂场景的替换。

|  |
| --- |
| awk '{gsub("原字符串","新字符串"); print}' 文件名 > 新文件 |

**参数说明：**

- gsub("原字符串", "新字符串")：全局替换每行中匹配的内容。
- print：输出替换后的每一行。
- 使用 > 将结果重定向到新文件中。

举例：替换 example.txt 中的 foo 为 bar 并将结果保存为 output.txt

|  |
| --- |
| #创建文件  vim /root/example.txt  foo  bar  foo  bar  zs  ls    #替换 example.txt 中的 foo 为 bar 并将结果保存为 output.txt  awk '{gsub("foo","bar"); print}' /root/example.txt > /root/output.txt |

1. **perl命令**

perl 也可以用于文本替换，尤其适合多行或复杂的正则表达式处理。

|  |
| --- |
| perl -pi -e 's/原字符串/新字符串/g' 文件名 |

**参数说明：**

- -p：逐行读取文件。
- -i：直接修改文件内容,建议提前备份文件。
- -e：执行指定的 Perl 脚本。

举例：替换 example.txt 中的所有 foo 为 bar。

|  |
| --- |
| #创建文件  vim /root/example.txt  foo  bar  foo  bar  zs  ls    #替换 example.txt 中的所有 foo 为 bar  perl -pi -e 's/foo/bar/g' /root/example.txt |

## 1.4 查找文件并替换内容

要求：请使用linux shell 将/data目录及其子目录下所有以扩展名.txt结尾的文件中包含girl的字符串全部替换为boy。

**命令：**

|  |
| --- |
| find /data -type f -name "\*.txt" -exec sed -i 's/girl/boy/g' {} + |

命令解释如下:

- find：查找命令，-type f 表示查找文件；-name 表示查找匹配模式名称的文件；-exec表示对查找到的文件执行命令。
- sed：文本替换工具，-i表示直接修改文件内容；{}表示当前查找到的文件。
- +:将多个文件一次性传递给命令，效率较高。

## 1.5 Linux命令获取文档内容

要求：Linux Shell命令中，如何输出一个文本文件的倒数第10行到倒数第5行的内容？

可以结合 tail 和 head 命令实现，假设文件为examples.txt文件，命令如下：

|  |
| --- |
| tail -n 10 examples.txt | head -n 6 |

命令解释如下：

- tail 命令：用于从文件末尾开始输出指定的行数。-n表示从文件末尾开始输出的行数。
- head命令：用于从文件开头开始输出指定的行数。-n表示从文件开头开始输出的行数。
- “|”：管道符，将 tail 输出的内容传递给 head命令。

## 1.6 Linux中如何获取上一条命令是否执行成功？

可以通过Linux内置变量“$?”获取上一条命令执行状态，根据状态值判断命令是否执行成功，当命令执行后，执行echo $? 即可查看上条命令执行是否成功，返回0表示命令执行成功，返回非零值表示命令执行失败。

“$?”是上一条命令的**退出状态码**，它的值是一个整数，表示命令的执行结果。如下是“$?”可能的常见值及含义：

|  |  |  |
| --- | --- | --- |
| **错误码** | **含义** | **示例** |
| **0** | 执行成功 | - |
| **1** | 一般错误 | 如：cd 到无效目录 |
| **2** | 误用命令或参数 | 如：ls 不存在的文件 |
| **126** | 无执行权限 | 尝试执行没有权限的文件，如：./xx.sh |
| **127** | 命令未找到 | 执行不存在的命令 |
| **128** | 无效退出参数 | 脚本退出时使用了非法的 exit 参数。如：exit 256 |
| **130** | 命令被终止（Ctrl+C） | 使用 Ctrl+C 中断命令，如 sleep 10 被中断 |
| **137** | 被 SIGKILL 信号终止 | 使用 kill -9 强制终止的进程 |
| **255** | 脚本错误退出 | 脚本中使用 exit 返回非法状态码（超过 255 的值会被取模） |

“$?”也常用于脚本中处理错误，如下：

|  |
| --- |
| #!/bin/bash  cp /root/aa /root/bb  if [ $? -ne 0 ]; then  echo "复制文件失败！"  else  echo "复制文件成功！"  fi |

注意：“[ $? -ne 0 ]”表示检查 $? 是否不等于 0，即判断上一条命令（cp）是否失败。

## 1.7 Linux脚本如何一次获取全部参数？

Shell 脚本可以通过特殊变量获取传递的参数：

|  |  |
| --- | --- |
| **特殊变量** | **含义** |
| $0 | 脚本名称 |
| $1 | 第一个参数 |
| $2 | 第二个参数 |
| $@ | 所有参数，按独立的字符串形式处理 |
| $\* | 所有参数，作为一个整体字符串处理 |
| $# | 参数个数 |

假设脚本名为/root/example.sh，内容如下：

|  |
| --- |
| #!/bin/bash  echo "脚本名称：$0"  echo "第一个参数：$1"  echo "第二个参数：$2"  echo "所有参数：$@"  for arg in "$@"; do  echo "参数：$arg"  done  echo "所有参数：$\*"  for arg in "$\*"; do  echo "参数：$arg"  done  echo "参数个数：$#" |

执行脚本：

|  |
| --- |
| sh /root/example.sh arg1 arg2 arg3 arg4 |

运行结果：

|  |
| --- |
| 脚本名称：example.sh  第一个参数：arg1  第二个参数：arg2  所有参数：arg1 arg2 arg3 arg4  参数：arg1  参数：arg2  参数：arg3  参数：arg4  所有参数：arg1 arg2 arg3 arg4  参数：arg1 arg2 arg3 arg4  参数个数：4 |

## 1.8 Linux中如何查看某个端口是否被占用？

在 Linux 节点中，确认某个端口是否被占用，可以使用netstat命令、ss命令、lsof 命令查看端口使用情况。

1. **使用netstat命令**

netstat 是一个非常常用的命令，可以用来确认某个端口是否被占用，命令如下：

|  |
| --- |
| **#需要提前安装 net-tools**  yum -y install net-tools    **#检查3306端口是否被占用,如果端口被占用，会看到类似如下输出**  netstat -tulnp | grep :3306  tcp6 0 0 :::3306 :::\* LISTEN 9089/mysqld |

netstat命令解释：

- -t：显示 TCP 连接。
- -u：显示 UDP 连接。
- -l：显示监听状态的端口。
- -n：以数字格式显示地址和端口，而不进行域名解析。
- -p：显示与每个连接关联的进程信息。

1. **使用ss命令**

ss 是 netstat 的替代工具，提供了更高效、更快的方式来查看网络连接,默认也能显示端口的使用情况。

|  |
| --- |
| **#检查3306端口是否被占用,如果端口被占用，会看到类似如下输出**  ss -tulnp | grep :3306  tcp LISTEN 0 80 :::3306 :::\* users:(("mysqld",pid=9089,fd=53)) |

ss命令解释：

- -t：显示 TCP 连接。
- -u：显示 UDP 连接。
- -l：显示监听状态的端口。
- -n：以数字格式显示地址和端口。
- -p：显示与每个连接关联的进程信息。

1. **使用lsof命令**

lsof（list open files）命令可以列出系统中打开的文件和进程,也可以用于查看特定端口是否被占用。

|  |
| --- |
| **#需要提前安装 lsof**  yum -y install lsof    **#检查3306端口是否被占用,如果端口被占用，会看到类似如下输出**  lsof -i :3306  COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME  mysqld 9089 mysql 53u IPv6 44964 0t0 TCP \*:mysql (LISTEN) :::\* |

注意，使用lsof时，后面跟上的端口需要加上冒号。lsof参数解释：

- -i：筛选出与网络有关的打开文件。

## 1.9 如何查看Linux节点某服务的进程号？

可以使用jps和ps命令查看对应服务的进程号，下面分别介绍。

1. jps（Java Virtual Machine Process Status Tool）是一个专门用于查看 Java 进程的命令,该命令会列出当前所有运行的 Java 进程及其对应的进程号（PID）。

jps使用方式如下：

|  |
| --- |
| jps  1234 NameNode  5678 DataNode  91011 ResourceManager |

1. ps（process status）是一个非常常用的 Linux 命令，用于显示当前系统中的进程信息，包括进程 ID、进程状态、资源使用情况等。

使用方式如下：

|  |
| --- |
| **#查看mysql服务进程号,aux表示显示所有进程的详细信息。**  ps aux | grep mysql  mysql 9089 0.1 4.9 1122440 189284 ? Sl 15:15 0:03 /usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid |

对于以上返回结果解释如下：

- mysql：表示进程的所有者是 mysql 用户。
- 9089：这是该进程的进程 ID（PID），表示这个 mysqld 进程的唯一标识符。
- 0.1：表示该进程的 CPU 使用率（百分比）。该进程当前使用了 0.1% 的 CPU。
- 4.9：表示该进程的内存使用率（百分比）。该进程当前使用了 4.9% 的系统内存。
- 1122440：表示该进程的虚拟内存大小（单位：KB）。即该进程分配的虚拟内存总量。
- 189284：表示该进程的常驻内存使用量（单位：KB）。这是该进程实际占用的物理内存大小。
- ?：表示该进程没有关联到一个终端（? 表示无终端）。
- Sl：进程的状态。

- S 表示进程处于睡眠状态（Sleep）。
- l 表示该进程是一个多线程进程（multi-threaded）。

- 15:15：表示进程的启动时间，即该进程在 15:15 启动。
- 0:03：表示进程已经运行的总时间（小时：分钟：秒）。在此示例中，进程已经运行了 0 小时 3 秒。
- /usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid：表示启动该进程的命令及其参数。/usr/sbin/mysqld 是 MySQL 数据库守护进程的路径，--daemonize 参数表示该进程以守护进程模式运行，--pid-file 参数指定了 MySQL 进程的 PID 文件路径。

## 1.10 如何查看systemctl系统命令启动服务的日志?

在大数据工作过程中，我们经常会使用 systemctl 命令启动安装的服务，例如：启动ClouderaManager Server服务如下:

|  |
| --- |
| systemctl start cloudera-scm-sever |

当我们把对应的服务启动之后，去对应服务日志目录查看日志即可。例如ClouderaManager Server对应的日志在 /var/log/cloudera-scm-server/cloudera-scm-server.log中。

如果启动对应服务后，服务启动失败，同时在对应的日志文件中没有任何错误信息，这说明在systemctl命令启动服务过程中，根本还没有执行到对应服务就已经失败，**这一般是由于一些系统依赖、系统环境问题导致，这就需要查看systemctl 启动服务产生的日志，通过 journalctl 命令来查看。**

journalctl 是 systemd 的日志管理工具，可用来查看与服务相关的日志，具体操作如下：

|  |
| --- |
| #实时显示所有的systemctl的日志，日志是系统所有服务混合日志  journalctl -f    #只实时查看某个服务对应的systemctl 日志  journalctl -f -u 服务名 |

以上命令参数解释如下：

- -f：实时查看日志（类似 tail -f）。
- -u:指定要查看日志的服务名称。

## 1.11 Linux查看节点资源使用情况命令

1. **top:查看节点资源使用情况（CPU、内存）**

|  |
| --- |
| **top**  [root@node1 ~]# top  top - 20:29:50 up 7:16, 1 user, load average: 0.00, 0.01, 0.05  Tasks: 113 total, 1 running, 112 sleeping, 0 stopped, 0 zombie  %Cpu(s): 0.0 us, 0.0 sy, 0.0 ni,100.0 id, 0.0 wa, 0.0 hi, 0.0 si, 0.0 st  KiB Mem : 3861520 total, 3585832 free, 109520 used, 166168 buff/cache  KiB Swap: 2097148 total, 2097148 free, 0 used. 3528432 avail Mem    PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND  28711 root 20 0 0 0 0 S 0.3 0.0 0:00.15 kworker/1  .... |

top返回结果解释如下：

- 第一行：系统信息。当前系统时间；系统运行时间；登录系统的用户数；系统1min/5min/15min平均负载。
- 第二行：Tasks任务状态。总共任务；正在运行任务；休眠状态任务；停止状态任务；僵尸进程数量（已完成但未被回收的进程）。
- 第三行：CPU使用情况。us（user，用户空间的 CPU 使用率）；sy（system，内核空间的 CPU 使用率）；ni（nice,优先级调整过的进程的 CPU 使用率）；id（idle,空闲的 CPU 百分比）；wa（iowait，等待 I/O 操作完成的 CPU 百分比）；hi（hardware interrupts,硬件中断的 CPU 使用率）；si（software interrupts，软件中断的 CPU 使用率）；st（steal time,虚拟机中其他操作系统占用的 CPU 时间比例）。
- 第四行：内存使用情况。总内存大小；空闲内存大小；已使用的内存大小；缓存和缓冲区使用的内存大小。
- 第五行：交换空间swap使用情况。总交换空间大小；空闲交换空间大小；已使用的交换空间大小；当前可用的内存。
- 最后部分为进程列表，PID(进程 ID)、USER（运行进程的用户）、PR（priority，进程优先级）、NI（nice，进程的调整优先级值）、VIRT（进程占用的虚拟内存大小）、RES（进程实际占用的物理内存大小）、SHR（进程使用的共享内存大小）、S（state，进程状态：R-Running/S-Sleeping/Z-zombie）、%CPU（进程的 CPU 使用率）、%MEM（进程的内存使用率）、TIME+（进程累计使用的 CPU 时间）、COMMAND（运行该进程的命令名称）。

1. **df：查看磁盘使用情况**

|  |
| --- |
| # -h表示以人类可读的格式显示磁盘使用信息  **df -h** |

1. **free:查看内存使用情况**

|  |
| --- |
| # -h表示以人类可读的格式显示内存和交换分区信息  **free -h**  total used free shared buff/cache available  Mem: 3.7G 107M 3.4G 11M 162M 3.4G  Swap: 2.0G 0B 2.0G |

free -h 返回的结果解释如下：

- total:总物理内存大小。
- used:已使用的内存大小。
- free:完全空闲的内存大小。
- shared:共享内存大小。
- buff/cache:缓存和缓冲区占用的内存。
- available:当前可用的内存大小。

## 1.12 Linux特殊内容替换

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

## 1.13 为hadoop用户赋予root权限该如何操作？

root是Linux中的超级用户，sudo命令允许普通用户以超级用户（root）身份运行命令，如果为hadoop用户赋予root权限需要在/etc/sudoers文件中做配置。

sudoers文件用于配置哪些用户或用户组可以使用 sudo 命令以提权执行任务的配置文件。

Centos系统中，为hadoop用户赋予root权限操作在/etc/sudoers文件中增加如下内容：

|  |
| --- |
| **#在 root ALL=(ALL) ALL 行下方加入如下内容**  hadoop ALL=(ALL) ALL |

“hadoop ALL=(ALL) ALL”这一行表示 hadoop用户可以在**任何主机上**以**任何用户身份**执行**所有命令**,命令解释如下：

- hadoop: 指定的用户是 hadoop。
- ALL: 表示适用于所有主机，通常用于本地机器的配置。
- (ALL): 表示 hadoop 用户可以以任何身份执行命令，默认情况下是 hadoop 身份。
- ALL: 表示 hadoop 用户可以运行系统上所有的命令。

配置以上完成后，可以切换hadoop用户，验证是否拥有root权限：

|  |
| --- |
| **#切换hadoop用户**  su hadoop    **#查看/root中文件，可以看到hadoop用户权限提升**  sudo ls /root  [sudo] hadoop 的密码：  anaconda-ks.cfg |

## 1.14 如何查看Linux系统版本

可以使用“cat /etc/os-release”、“cat /proc/version”、“uname -a”三种命令查询。

- “cat /etc/os-release”：显示发行版名称、版本号以及其他相关信息。
- “cat /proc/version”：显示内核版本、编译时间、编译器等信息，不会提供关于发行版的详细信息（如 Ubuntu、CentOS 等）。
- “uname -a”：显示内核版本、主机名和编译时间信息。

## 1.15 列举linux Shell中常用的命令？

1. **文件与目录操作**

ls：列出目录内容。

cd：改变当前工作目录。

pwd：显示当前工作目录的路径。

mkdir：创建目录。

rmdir：删除空目录。

rm：删除文件或目录。

cp：复制文件或目录。

mv：移动或重命名文件/目录。

1. **文件内容操作**

cat：显示文件内容。

more：分页显示文件内容。

less：分页显示文件内容，支持向前和向后滚动。

head：显示文件的前几行。

tail：显示文件的最后几行。

grep：在文件中查找指定模式的内容。

find：在指定目录中查找文件或目录。

1. **文件权限管理**

chmod：改变文件或目录的权限。

chown：改变文件或目录的所有者。

chgrp：改变文件或目录的组。

1. **系统与进程管理**

ps：显示当前正在运行的进程。

top：实时显示系统的进程、内存、CPU 使用情况。

kill：终止指定进程。

killall：终止指定名称的所有进程。

df：查看文件系统的磁盘空间使用情况。

1. **网络与连接管理**

ping：测试与远程主机的网络连接。

ifconfig：查看和配置网络接口（常见于老版本 Linux，已被 ip 替代）。

ip：查看和配置网络接口、路由和设备等（比 ifconfig 更为现代）。

netstat：显示网络连接、路由表和接口统计信息。

wget：从网络下载文件。

curl：发送 HTTP 请求，获取或发送数据。

1. **压缩与解压**

tar：压缩或解压 .tar 格式的文件。

gzip：压缩文件为 .gz 格式。

gunzip：解压 .gz 格式的文件。

zip：创建 .zip 格式的压缩文件。

unzip：解压 .zip 格式的压缩文件。

1. **文件重定向与管道**

>：输出重定向，将命令输出写入文件，覆盖原文件。

>>：输出重定向，将命令输出追加到文件末尾。

|：管道，将一个命令的输出作为另一个命令的输入。

1. **环境与变量管理**

export：设置环境变量，使其在子进程中可用。

echo：显示信息或变量内容。

env：显示当前的环境变量。

1. **文本处理**

vim/vi : 操作文件

awk：一个强大的文本处理工具，用于按列处理文本文件，支持模式匹配、字段分割等。

sed：流编辑器，用于处理文本流，支持查找、替换、删除等操作。

sort：排序文件内容。

## 1.16 shell命令提取文本指定内容到不同文件

有a.txt文件，内容如下：

|  |
| --- |
| 1,zs,18,100  2,ls,19,200  3,ww,20,300 |

使用shell命令将各个列获取出来分别放入独立的文件中。

实现如上功能的Shell命令如下：

|  |
| --- |
| **#提取第1列**  awk -F',' '{print $1}' a.txt > col1.txt  **#提取第2列**  awk -F',' '{print $2}' a.txt > col1.txt  **#提取第3列**  awk -F',' '{print $3}' a.txt > col1.txt  **#提取第4列**  awk -F',' '{print $4}' a.txt > col1.txt |

以上命令解释如下：

- awk:linux中强大的文本处理工具，常用于对文本数据进行模式匹配和处理。
- -F','：该选项指定字段分隔符为逗号（,）。默认情况下，awk 以空白字符（空格或制表符）作为字段分隔符。使用 -F','，awk 将每行按逗号分隔为多个字段。
- '{print $1}'：awk 的操作指令。{} 内的内容表示对每一行执行的操作。print $1 表示输出当前行的第一个字段。在 awk 中，$1 代表第一列，$2 代表第二列，以此类推。
- a.txt：这是输入文件的名称，包含待处理的数据。
- > col1.txt：输出重定向操作。将前面 awk 命令的输出保存到指定文件中。如果文件存在，该操作会覆盖其内容；如果不存在，则会创建该文件。

也可以通过如下命令使用for循环将各列写入到不同的文件：

|  |
| --- |
| for i in {1..4}; do awk -F',' "{print \$$i}" a.txt > "col$i.txt"; done |

注意：需要使用双引号 " 包围 awk 的代码部分，使得 shell 可以解析其中的变量$i;在“{print \$$i}”中引用 shell 变量 i，需要使用 \$$i。其中，\$ 表示 awk 中的字段引用符号 $，而 $i 是 shell 变量，表示当前循环的索引值。

## 1.17 shell命令实现文件内容去重

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
