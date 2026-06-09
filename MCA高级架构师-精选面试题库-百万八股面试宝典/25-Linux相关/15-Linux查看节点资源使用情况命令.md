## **top:查看节点资源使用情况（CPU、内存）**

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

## **df：查看磁盘使用情况**

|  |
| --- |
| # -h表示以人类可读的格式显示磁盘使用信息  **df -h** |

## **free:查看内存使用情况**

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
