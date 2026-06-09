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
