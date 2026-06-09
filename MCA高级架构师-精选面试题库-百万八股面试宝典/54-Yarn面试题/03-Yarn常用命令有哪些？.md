## **查看Yarn中资源情况**

命令：yarn top ，可以通过该命令实时查看application资源使用情况。

|  |
| --- |
| [root@node5 ~]# **yarn top**  YARN top - 20:00:09, up 0d, 4:23, 0 active users, queue(s): root  NodeManager(s): 3 total, 3 active, 0 unhealthy, 0 decommissioning, 0 decommissioned, 0 lost, 0 rebooted, 0 shutdown  Queue(s) Applications: 0 running, 5 submitted, 0 pending, 4 completed, 1 killed, 0 failed  Queue(s) Mem(GB): 24 available, 0 allocated, 0 pending, 0 reserved  Queue(s) VCores: 24 available, 0 allocated, 0 pending, 0 reserved  Queue(s) Containers: 0 allocated, 0 pending, 0 reserved  ... ... |

## **查看Yarn Node**

命令：yarn node -list -all ，查看所有Yarn NodeManager节点信息

|  |
| --- |
| [root@node5 ~]# **yarn node -list -all**  Total Nodes:3  Node-Id Node-State Node-Http-Address Number-of-Running-Containers  node4:44298 RUNNING node4:8042 0  node3:38712 RUNNING node3:8042 0  node5:43801 RUNNING node5:8042 0 |

## **列出所有Application**

命令：yarn application -list，列出所有Yarn中SUBMITTED, ACCEPTED, RUNNING的Applications。

|  |
| --- |
| **#提交wordcount任务2次**  [root@node5 ~]# **hadoop jar /software/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input/data.txt /output1**  [root@node5 ~]# **hadoop jar /software/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input/data.txt /output2**  **#查看执行任务**  [root@node5 ~]# **yarn application -list**  Total number of applications (application-types: [], states: [SUBMITTED, ACCEPTED, RUNNING] and tags: []):2  Application-Id Application-Name Application-Type User Queue State Fi  nal-State Progress Tracking-URLapplication\_1713246389325\_0001 word count MAPREDUCE root default RUNNING  UNDEFINED 5% http://node3:41018application\_1713246389325\_0002 word count MAPREDUCE root default ACCEPTED  UNDEFINED 0% N/A |

## **过滤Application状态**

命令：yarn application -list -appStates [ALL、NEW、NEW\_SAVING、SUBMITTED、ACCEPTED、RUNNING、FINISHED、FAILED、KILLED]，根据Application运行状态进行过滤。以上各种状态含义如下：

- ALL：所有状态应用程序。
- NEW：应用程序刚创建时的状态。应用程序会被分配一个唯一的Application ID，但还没有分配资源，也没有进入资源队列。
- NEW\_SAVING：应用程序等待资源保存。这个状态只存在于开启了Application历史保存的集群上，如果没有保存历史，则该状态的转换不会发生。
- SUBMITTED：应用程序已经提交给YARN，并在队列中等待调度资源。在该状态下，YARN只是对应用程序进行了初步的运行时配置，但还没有将任何容器分配到该应用程序。
- ACCEPTED：应用程序已经通过队列，并已经分配了它需要的初始和最小容器。
- RUNNING：应用程序正在运行中，并具有正在运行的容器。
- FINISHED：应用程序已经成功完成，并且其最终状态已经保存到YARN应用历史中。
- FAILED：应用程序运行失败，并且其最终状态已经保存到YARN应用历史中。
- KILLED：应用程序已被终止，并且其最终状态已经保存到YARN应用历史中。

|  |
| --- |
| [root@node5 ~]# **yarn application -list -appStates FINISHED**  Total number of applications (application-types: [], states: [FINISHED] and tags: []):2  Application-Id Application-Name Application-Type User Queue State Fi  nal-State Progress Tracking-URLapplication\_1713246389325\_0001 word count MAPREDUCE root default FINISHED  SUCCEEDED 100% http://node3:19888/jobhistory/job/job\_1713246389325\_0001application\_1713246389325\_0002 word count MAPREDUCE root default FINISHED  SUCCEEDED 100% http://node3:19888/jobhistory/job/job\_1713246389325\_0002 |

## **停止Application**

命令：yarn application -kill [applicationId] ，Kill掉指定applicationdi的application。

|  |
| --- |
| **#提交wordcount任务**  [root@node5 ~]# **hadoop jar /software/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /input/data.txt /output3**  **#在Yarn Webui中可以看到对应执行的Yarn任务ID，将正在执行的任务kill掉**  [root@node5 ~]# **yarn application -kill application\_1713339414240\_0003**  Killing application application\_1713339414240\_0003  INFO impl.YarnClientImpl: Killed application application\_1713339414240\_0003 |

## **查看Application日志**

命令：yarn logs -application <applicationId> ,查看指定application的日志。

|  |
| --- |
| [root@node5 ~]# **yarn logs -applicationId application\_1713339414240\_0003**  ... ...  End of LogType:syslog.shuffle  \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |

## **查看Application Attempt任务**

命令：yarn applicationattempt -list <applicationId>，列出指定application的attempt列表。

命令：yarn applicationattempt -status <applicationAttemptId> ,输出指定attemptId对应执行结果。

|  |
| --- |
| **#列出指定application的attempt列表**  [root@node5 ~]# **yarn applicationattempt -list application\_1713339414240\_0003**  Total number of application attempts :1  ApplicationAttempt-Id State AM-Container-Id Tracking-URL  appattempt\_1713339414240\_0003\_000001 FINISHED container\_1713339414240\_0003\_01\_000001 <http://node1:8088/proxy/application_1713339414240_0003/>  **#输出指定attemptId对应执行结果**  [root@node5 ~]# **yarn applicationattempt -status appattempt\_1713339414240\_0003\_000001**  Application Attempt Report :  ApplicationAttempt-Id : appattempt\_1713339414240\_0003\_000001  State : FINISHED  AMContainer : container\_1713339414240\_0003\_01\_000001  Tracking-URL : http://node1:8088/proxy/application\_1713339414240\_0003/  RPC Port : 42688  AM Host : node4  Diagnostics : |

## **列出Attempt任务container信息**

命令：yarn container -list <applicationAttemptId>，列出指定applicationAttemptId的Container。

命令：yarn container -status <containerId> ,列出指定ContainerId的状态。

注意：查看Container信息必须在Container运行情况下查询，因为Container运行结束后就会停止。

|  |
| --- |
| **#提交MapReduce自带Pi计算任务，第一个参数是map个数，第二个参数是计算pi的样本数**  [root@node5 ~]# **hadoop jar /software/hadoop-3.3.6/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar pi 100 10000**  **#查看当前application的attemptId任务**  [root@node5 ~]# **yarn applicationattempt -list application\_1713339414240\_0005**  Total number of application attempts :1  ApplicationAttempt-Id State AM-Container-Id Tracking-URL  appattempt\_1713339414240\_0005\_000001 RUNNING container\_1713339414240\_0005\_01\_000001 http://node1:8088/proxy/application\_17133  39414240\_0005/  **#查看当前attemptId任务的container信息**  [root@node5 ~]# **yarn container -list appattempt\_1713339414240\_0005\_000001**  Total number of containers :23  Container-Id Start Time Finish Time State Host Node Http Addr  ess LOG-URLcontainer\_1713339414240\_0005\_01\_000001 N/A RUNNING node4:42  605 http://node4:8042 http://node4:8042/node/containerlogs/container\_1713339414240\_0005\_01\_000001/rootcontainer\_1713339414240\_0005\_01\_000060 N/A RUNNING node4:42  605 http://node4:8042 <http://node4:8042/node/containerlogs/container_1713339414240_0005_01_000060/root>  ... ...  **#查看指定containerId的状态信息**  [root@node5 ~]# **yarn container -status container\_1713339414240\_0005\_01\_000001**  Container Report :  Container-Id : container\_1713339414240\_0005\_01\_000001  Start-Time : 1713341157747  Finish-Time : 0  State : RUNNING  Execution-Type : GUARANTEED  LOG-URL : http://node4:8042/node/containerlogs/container\_1713339414240\_0005\_01\_000001/root  Host : node4:42605  NodeHttpAddress : http://node4:8042  ExposedPorts :  Diagnostics : null |

## **查看container日志信息**

命令：yarn logs -applicationId <ApplicationId> -containerId <ContainerId>，查看某个application下containerId的运行日志。

|  |
| --- |
| [root@node5 ~]# **yarn logs -applicationId application\_1713339414240\_0005 -containerId container\_1713339414240\_0005\_01\_000001**  ... ...  End of LogType:syslog  \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* |

## **查看Yarn指定资源队列状态**

命令：yarn queue -status <QueueName>，查看队列状态，可以通过yarn top查看对应的资源队列有哪些。

|  |
| --- |
| [root@node5 ~]# **yarn queue -status root**  Queue Information :  Queue Name : root //资源队列的名称  State : RUNNING //资源队列的状态  Capacity : 100.00% //资源队列的容量  Current Capacity : .00% //资源队列已占用的容量  Maximum Capacity : 100.00% //资源队列最大容量限制  Default Node Label expression : <DEFAULT\_PARTITION> //默认资源节点标签，节点标签是一种将集群中的节点进行逻辑分组的机制，它可以用来限制任务的调度范围，从而实现资源的灵活管理和利用。  Accessible Node Labels : \* //资源队列可以访问的节点标签  Preemption : disabled //资源队列是否启动抢占功能。如果开启，会在系统资源不足时，强制终止正在运行的低优先级任务，以便高优先级任务先运行。  Intra-queue Preemption : disabled //资源队列内是否禁用抢占功能。 |

## **加载资源队列配置**

命令：yarn rmadmin -refreshQueues，该命令会加载资源队列配置。

|  |
| --- |
| [root@node5 ~]# yarn rmadmin -refreshQueues |
