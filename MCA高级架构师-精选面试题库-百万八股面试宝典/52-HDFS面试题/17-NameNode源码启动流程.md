NameNode源码启动类为org.apache.hadoop.hdfs.server.namenode.NameNode，当启动NameNode后会执行该类的main方法，在该类main方法中会创建NameNode对象，代码如下:

|  |
| --- |
| public static void main(String argv[]) throws Exception {  ... ....  *// createNameNode返回NameNode对象*NameNode namenode = *createNameNode*(argv, null);  ... ...  } |

在createNameNode方法中实际上最终返回“new NameNode(conf)”对象，在NameNode构造函数中会执行“initialize(...)”方法来进行NameNode启动流程。NameNode构建方法如下：

|  |
| --- |
| public NameNode(Configuration conf) throws IOException {  *//这里第二个参数为 “NameNode"* this(conf, NamenodeRole.*NAMENODE*); } |

this调用到2个参数构造：

|  |
| --- |
| protected NameNode(Configuration conf, NamenodeRole role)  throws IOException {  ... ...  *// initialize中执行NameNode启动流程*initialize(getConf());  ... ...  } |

在initialize方法中NameNode启动主要经过如下4个过程：

1. 启动NameNode HttpServer ，方便用户通过http访问HDFS WebUI
2. 加载本地fsimage和editslog
3. 创建NameNode RpcServer并启动
4. 检测集群是否处于安全模式

initialize方法主要代码实现如下：

|  |
| --- |
| protected void initialize(Configuration conf) throws IOException {  ... ...  *//判断是NameNode角色*if (NamenodeRole.*NAMENODE* == role) {  *//1.启动 NameNode httpserver ，用户可以通过http访问WebUI* startHttpServer(conf); }  *//2.加载本地文件中的镜像文件和editslog到内存中*loadNamesystem(conf);  ... ...  *//3.createRpcServer 创建 NameNodeRpc服务端*rpcServer = createRpcServer(conf);  ... ...  *//4.启动CommoneService 进行 NameNode资源检查和安全模式检查*startCommonServices(conf);  ... ...  } |

下面分别对以上过程进行介绍。

## **启动NameNode HttpServer**

startHttpServer方法主要创建HttpServer ，这样用户就可以通过WebUI来访问NameNode。startHttpServer代码如下：

|  |
| --- |
| private void startHttpServer(final Configuration conf) throws IOException {  *//getHttpServerBindAddress 中绑定了NameNode的IP和端口 9870* httpServer = new NameNodeHttpServer(conf, this, getHttpServerBindAddress(conf));  *//启动Http server* httpServer.start();  httpServer.setStartupProgress(*startupProgress*); } |

getHttpServerBindAddress(conf)中进行了NameNode节点IP和端口9870绑定并返回InetSocketAddress对象，getHttpServerBindAddress(conf)源码如下:

|  |
| --- |
| protected InetSocketAddress getHttpServerBindAddress(Configuration conf) {  *//getHttpServerAddress 绑定NameNode IP及端口 9870* InetSocketAddress bindAddress = getHttpServerAddress(conf);   *// If DFS\_NAMENODE\_HTTP\_BIND\_HOST\_KEY exists then it overrides the*  *// host name portion of DFS\_NAMENODE\_HTTP\_ADDRESS\_KEY.*  *//获取 NameNode host主机* final String bindHost = conf.getTrimmed(*DFS\_NAMENODE\_HTTP\_BIND\_HOST\_KEY*);  if (bindHost != null && !bindHost.isEmpty()) {  bindAddress = new InetSocketAddress(bindHost, bindAddress.getPort());  }   return bindAddress; } |

以上源码中getHttpServerAddress会绑定节点IP和端口。

在startHttpServer方法中的httpServer.start()方法进行了HttpServer2封装，Hadoop中使用了自己的Httpserver进行Kerberos认证，最后通过HttpServer2.Builder.build()方法创建了hdfs自己的httpserver并调用start方法进行启动。

httpServer.start()具体源码如下：

|  |
| --- |
| void start() throws IOException {  ... ...  *//Hadoop中封装了自己的Httpserver，形成自己的Httpserver2*HttpServer2.Builder builder = DFSUtil.*httpServerTemplateForNNAndJN*(conf,  httpAddr, httpsAddr, "hdfs",  DFSConfigKeys.*DFS\_NAMENODE\_KERBEROS\_INTERNAL\_SPNEGO\_PRINCIPAL\_KEY*,  DFSConfigKeys.*DFS\_NAMENODE\_KEYTAB\_FILE\_KEY*);  ... ...  *//启动 httpServer 服务*httpServer.start();  ... ...  } |

## **加载fsimage和editslog**

loadNamesystem(conf)中会加载本地fsimage和editslog,具体源码如下：

|  |
| --- |
| protected void loadNamesystem(Configuration conf) throws IOException {  *//从磁盘中加载editslog和fsimage* this.namesystem = FSNamesystem.*loadFromDisk*(conf); } |

loadFromDisk源码如下：

|  |
| --- |
| static FSNamesystem loadFromDisk(Configuration conf) throws IOException {  ... ...  *// 封装FSImage对象*FSImage fsImage = new FSImage(conf,  FSNamesystem.*getNamespaceDirs*(conf),  FSNamesystem.*getNamespaceEditsDirs*(conf));*//创建 FSNamesystem 对象，并对该对象中fsimage 属性赋值fsimage*FSNamesystem namesystem = new FSNamesystem(conf, fsImage, false);  ... ...  *//加载fsImage*namesystem.loadFSImage(startOpt);  .... ...  } |

## **创建NameNode RpcServer并启动**

创建NameNode RpcServer的代码如下：

|  |
| --- |
| rpcServer = createRpcServer(conf);  *//3.createRpcServer 创建 NameNodeRpc服务端和客户端*rpcServer = createRpcServer(conf); |

createRpcServer源码如下：

|  |
| --- |
| protected NameNodeRpcServer createRpcServer(Configuration conf)  throws IOException {  return new NameNodeRpcServer(conf, this); } |

在“new NameNodeRpcServer(conf, this)”创建nameNodeRpcServer对象中会创建NameNode作为Rpc 服务端和客户端的RpcServer，具体源码如下：

|  |
| --- |
| public NameNodeRpcServer(Configuration conf, NameNode nn)  throws IOException {  ... ...  serviceRpcServer = new RPC.Builder(conf)  .setProtocol(  org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolPB.class)  .setInstance(clientNNPbService)  .setBindAddress(bindHost)  .setPort(serviceRpcAddr.getPort())  .setNumHandlers(serviceHandlerCount)  .setVerbose(false)  .setSecretManager(namesystem.getDelegationTokenSecretManager())  .build();  ... ..  clientRpcServer = new RPC.Builder(conf)  .setProtocol(  org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolPB.class)  .setInstance(clientNNPbService)  .setBindAddress(bindHost)  .setPort(rpcAddr.getPort())  .setNumHandlers(handlerCount)  .setVerbose(false)  .setSecretManager(namesystem.getDelegationTokenSecretManager())  .setAlignmentContext(stateIdContext)  .build();  ... ...  } |

关于NameNode serviceRpcServer和clientRpcServer的启动在后续NameNode资源检测后启动。

## **检测集群是否处于安全模式**

经过前面3个步骤后，会执行如下代码进行资源检查和安全模式检查：

|  |
| --- |
| *//4.启动CommoneService 进行 NameNode资源检查和安全模式检查*startCommonServices(conf); |

startCommonServices方法实现如下：

|  |
| --- |
| private void startCommonServices(Configuration conf) throws IOException {  ... ...  *//启动服务 检测磁盘空间和安全模式*namesystem.startCommonServices(conf, haContext);  ... ...  *//这里启动的是NameNode RpcServer，会启动Name 作为客户端的clientRpcServer 和作为服务端的serviceRpcServer*rpcServer.start();  ... ...  } |

以上namesystem.startCommonServices(conf, haContext);主要负责磁盘空间和安全模式检测；rpcServer.start();主要进行NameNode serviceRpcServer和clientRpcServer的启动。

startCommonServices(conf, haContext)方法具体源码如下：

|  |
| --- |
| void startCommonServices(Configuration conf, HAContext haContext) throws IOException {  ... ...  *//nnResourceChecker 对象用于后续检查editslog 目录空间是否足够*nnResourceChecker = new NameNodeResourceChecker(conf);*//检查是否有足够磁盘空间存储数据*checkAvailableResources();assert !blockManager.isPopulatingReplQueues();StartupProgress prog = NameNode.*getStartupProgress*();*//开始进入安全模式*prog.beginPhase(Phase.*SAFEMODE*);*//获取所有可用的block*long completeBlocksTotal = getCompleteBlocksTotal();*//设置安全模式*prog.setTotal(Phase.*SAFEMODE*, *STEP\_AWAITING\_REPORTED\_BLOCKS*,  completeBlocksTotal);*//启动块服务并对DataNode 心跳超时进行判断*blockManager.activate(conf, completeBlocksTotal);  ... ...  } |

以上代码中nnResourceChecker = new NameNodeResourceChecker(conf);中会设置磁盘空间最小阈值100M，然后执行checkAvailableResources();方法进行检查节点磁盘空间是充足，具体代码如下：  
new NameNodeResourceChecker(conf)源码:

|  |
| --- |
| public NameNodeResourceChecker(Configuration conf) throws IOException {  ... ...  *// duReserved 默认为100M*duReserved = conf.getLongBytes(DFSConfigKeys.*DFS\_NAMENODE\_DU\_RESERVED\_KEY*,  DFSConfigKeys.*DFS\_NAMENODE\_DU\_RESERVED\_DEFAULT*);  ... ...  } |

checkAvailableResources()源码如下：

|  |
| --- |
| void checkAvailableResources() {  ... ...  *//判断磁盘资源是否够用*hasResourcesAvailable = nnResourceChecker.hasAvailableDiskSpace();  ... ...  } |

其中以上hasAvailableDiskSpace方法实现如下：

|  |
| --- |
| public boolean hasAvailableDiskSpace() {  return NameNodeResourcePolicy.*areResourcesAvailable*(volumes.values(),  minimumRedundantVolumes); } |

该方法如果返回true表示至少有一个配置的磁盘空间满足使用。方法中areResourcesAvailable实现源码如下：

|  |
| --- |
| tatic boolean areResourcesAvailable(  Collection<? extends CheckableNameNodeResource> resources,  int minimumRedundantResources) {  *... ...*  *//检查资源是否充足*for (CheckableNameNodeResource resource : resources) {  if (!resource.isRequired()) {  redundantResourceCount++;  *// isResourceAvailable 实现类为 NameNodeResourceChecker.CheckedVolume中的isResourceAvailable 方法* if (!resource.isResourceAvailable()) {  disabledRedundantResourceCount++;  }  } else {  requiredResourceCount++;  if (!resource.isResourceAvailable()) {  *// Short circuit - a required resource is not available.* return false;  }  } }  *... ...*  } |

其中resource.isResourceAvailable()中判断磁盘是否满足最低的100M，返回true表示满足，返回false表示不满足。isResourceAvailable()实现类是NameNodeResourceChecker.CheckedVolume中的isResourceAvailable方法，该方法中进行磁盘空间判断是否满足最低100M,具体判断源码如下：

|  |
| --- |
| public boolean isResourceAvailable() {  ... ...  *//如果磁盘空间小于100M 返回fasle*if (availableSpace < duReserved) {  *LOG*.warn("Space available on volume '" + volume + "' is "  + availableSpace +  ", which is below the configured reserved amount " + duReserved);  return false; } else {  return true; }  ... ...  } |

检测完磁盘可用空间后，进入安全模式，并进行可用block的检测,进而判断是否退出NameNode安全模式，具体源码在FSNmaesystem.startCommonServices中，如下：

|  |
| --- |
| *... ...*  *//开始进入安全模式*prog.beginPhase(Phase.*SAFEMODE*);*//获取所有可用的block*long completeBlocksTotal = getCompleteBlocksTotal();*//设置安全模式*prog.setTotal(Phase.*SAFEMODE*, *STEP\_AWAITING\_REPORTED\_BLOCKS*,  completeBlocksTotal);  *//检测DataNode状态及是否退出安全模式*blockManager.activate(conf, completeBlocksTotal);  ... ... |

以上代码中“blockManager.activate(conf, completeBlocksTotal);”进行block块检测，查看正常可用block数是否满足总block的99.9% 可用，active(conf,completeBlocksTotal)具体源码如下：

|  |
| --- |
| public void activate(Configuration conf, long blockTotal) {  ... ...  *//datanodeManager对象对周期检查DataNode连接情况*datanodeManager.activate(conf);    ... ...  *//检测 正常 block 情况*bmSafeMode.activate(blockTotal);  ... ...  } |

datanodeManager.activate(conf)主要进行DataNode节点是否宕机，默认经过10分钟+30s一个DataNode没有向NameNode汇报心跳信息，则该DataNode宕机。datanodeManager.activate(conf)实现源码如下：

|  |
| --- |
| void activate(final Configuration conf) {  datanodeAdminManager.activate(conf);  *//与DataNode心跳检测* heartbeatManager.activate(); } |

heartbeatManager.activate()中activate方法最终调用到Monitor线程的run方法进行DataNode状态监测。

bmSafeMode.activate(blockTotal)进行是否退出安全模式检车，实现源码如下：

|  |
| --- |
| void activate(long total) {  ... ...  *//设置正常可用block，并设置正常退出安全模式阈值为0.999f*setBlockTotal(total);if (areThresholdsMet()) {*//判断是否可以退出安全模式，block和datanode阈值都满足退出* boolean exitResult = leaveSafeMode(false);  Preconditions.*checkState*(exitResult, "Failed to leave safe mode."); } else {*//进入安全模式*  *// enter safe mode* status = BMSafeModeStatus.*PENDING\_THRESHOLD*;  initializeReplQueuesIfNecessary();  reportStatus("STATE\* Safe mode ON.", true);  lastStatusReport = *monotonicNow*(); }  ... ...  } |

其中“setBlockTotal(total);”设置正常可用block的阈值，“areThresholdsMet()”进行可用block是否满足阈值，areThresholdsMet()实现如下：

|  |
| --- |
| private boolean areThresholdsMet() {  //*如果block和datanode阈值都满足，则为True，否则返回false*  ... ...  synchronized (this) {  boolean isBlockThresholdMet = (blockSafe >= blockThreshold);  boolean isDatanodeThresholdMet = true;  if (isBlockThresholdMet && datanodeThreshold > 0) {  int datanodeNum = blockManager.getDatanodeManager().  getNumLiveDataNodes();  isDatanodeThresholdMet = (datanodeNum >= datanodeThreshold);  }  return isBlockThresholdMet && isDatanodeThresholdMet; }  } |
