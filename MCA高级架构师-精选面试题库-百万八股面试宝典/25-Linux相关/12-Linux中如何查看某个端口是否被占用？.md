在 Linux 节点中，确认某个端口是否被占用，可以使用netstat命令、ss命令、lsof 命令查看端口使用情况。

## **使用netstat命令**

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

## **使用ss命令**

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

## **使用lsof命令**

lsof（list open files）命令可以列出系统中打开的文件和进程,也可以用于查看特定端口是否被占用。

|  |
| --- |
| **#需要提前安装 lsof**  yum -y install lsof    **#检查3306端口是否被占用,如果端口被占用，会看到类似如下输出**  lsof -i :3306  COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME  mysqld 9089 mysql 53u IPv6 44964 0t0 TCP \*:mysql (LISTEN) :::\* |

注意，使用lsof时，后面跟上的端口需要加上冒号。lsof参数解释：

- -i：筛选出与网络有关的打开文件。
