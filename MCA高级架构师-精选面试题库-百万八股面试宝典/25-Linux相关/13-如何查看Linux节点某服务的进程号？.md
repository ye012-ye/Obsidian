可以使用jps和ps命令查看对应服务的进程号，下面分别介绍。

## jps（Java Virtual Machine Process Status Tool）

jps是一个专门用于查看 Java 进程的命令,该命令会列出当前所有运行的 Java 进程及其对应的进程号（PID）。

jps使用方式如下：

|  |
| --- |
| jps  1234 NameNode  5678 DataNode  91011 ResourceManager |

## ps（process status）

ps是一个非常常用的 Linux 命令，用于显示当前系统中的进程信息，包括进程 ID、进程状态、资源使用情况等。

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
