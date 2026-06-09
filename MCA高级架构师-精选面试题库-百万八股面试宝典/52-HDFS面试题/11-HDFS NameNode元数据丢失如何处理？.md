NameNode元数据丢失主要指当NameNode上元数据出现意外删除情况，如何进行集群恢复。

启动HDFS集群后，通过HDFS WebUI查看Active NameNode节点，并kill对应进程，删除该NameNode节点元数据目录。

|  |
| --- |
| **#查看进程**  [root@node1 software]# jps  10326 DFSZKFailoverController  9881 NameNode  10524 ResourceManager  11311 Jps    **#kill掉NameNode进程**  [root@node1 software]# kill -9 9881    **#删除对应NameNode节点元数据目录**  [root@node1 ~]# cd /opt/data/hadoop/dfs  [root@node1 dfs]# rm -rf ./name/ |

当kill掉对应的DataNode进程后，由于集群是HA模式，会自动切换其他Standby NameNode为Active状态。

然后，重启刚kill节点上的NameNode，由于删除了对应的元数据目录导致元数据目录丢失，会报错：

|  |
| --- |
| **#启动NameNode角色**  [root@node1 dfs]# hdfs --daemon start namenode    **#错误信息如下**  [root@node1 ~]# tail -n100 /software/hadoop-3.3.6/logs/hadoop-root-namenode-node1.log org.apache.hadoop.hdfs.server.common.InconsistentFSStateException: Directory /opt/data/hadoop/dfs/name is in an inconsistent state: storage direc  tory does not exist or is not accessible. at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverStorageDirs(FSImage.java:392)  at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverTransitionRead(FSImage.java:243)  at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFSImage(FSNamesystem.java:1236)  at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFromDisk(FSNamesystem.java:808)  at org.apache.hadoop.hdfs.server.namenode.NameNode.loadNamesystem(NameNode.java:694)  at org.apache.hadoop.hdfs.server.namenode.NameNode.initialize(NameNode.java:781)  at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:1033)  at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:1008)  at org.apache.hadoop.hdfs.server.namenode.NameNode.createNameNode(NameNode.java:1782)  at org.apache.hadoop.hdfs.server.namenode.NameNode.main(NameNode.java:1847) |

解决以上这个错误，只需要将其他NameNode节点上对应的元数据目录复制过来即可，假设当前NameNode在被kill之前有部分元数据没来得及同步给其他的StandbyNameNode，有可能造成数据丢失。具体操作如下：

|  |
| --- |
| **#将其他Active NameNode节点上的元数据发送到NameNode 元数据丢失节点**  [root@node2 ~]# cd /opt/data/hadoop/dfs/  [root@node2 dfs]# scp -r ./\* node1:`pwd`    **#再次在NameNode 元数据丢失节点上启动NameNode进程，可以看到进程正常启动**  [root@node1 ~]# hdfs --daemon start namenode |

启动NameNode进程后，该节点为Standby状态，可以参与正常的Active NameNode切换。
