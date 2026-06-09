Hadoop生态中常见的端口号如下：

|  |  |  |
| --- | --- | --- |
| **组件** | **功能** | **默认端口** |
| NameNode | HTTP服务端口 | 2.x版本：50070  3.x版本：9870 |
| NameNode | RPC服务端口 | 非高可用：9000  高可用：8020 |
| Secondary NameNode | HTTP服务端口 | 2.x版本：50090  3.x版本：9868 |
| DataNode | 与客户端或其他 DataNode 进行数据传输端口 | 2.x版本：50010  3.x版本：9864 |
| DataNode | 与 NameNode 进行通信端口 | 2.x版本：50020  3.x版本：9866 |
| JournalNode | HTTP服务端口 | 8480 |
| JournalNode | RPC服务端口 | 8485 |
| ResourceManager | Web UI端口 | 8088 |
| NodeManager | Web UI端口 | 8042 |
| MapReduce JobHistoryServer | Web UI端口 | 19888 |
| zookeeper | 客户端连接端口 | 2181 |
| Hive | Metastore元数据服务端口 | 9083 |
| Hive | HiveServer2 Thrift服务端口 | 10000 |
| HBase | HBase Master WebUI端口 | 16010 |
| Spark | Spark提交任务端口 | 7077 |
| Spark | Spark Master WebUI端口 | 8080 |
| Spark | Spark Worker WebUI端口 | 8081 |
| Spark | Spark Driver WebUI端口 | 4040 |
| Flink | Flink WebUI端口 | 8081 |
| Kafka | Kafka集群节点间通信端口 | 9092 |
