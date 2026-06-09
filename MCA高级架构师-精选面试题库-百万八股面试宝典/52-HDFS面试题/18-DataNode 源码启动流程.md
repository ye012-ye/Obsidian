DataNode启动源码类为org.apache.hadoop.hdfs.server.datanode.DataNode,该类main方法如下：

|  |
| --- |
| public static void secureMain(String args[], SecureResources resources) {  ... ...  DataNode datanode = *createDataNode*(args, null, resources);  ... ...  } |

createDataNode(args, null, resources)实现如下：

|  |
| --- |
| public static DataNode createDataNode(String args[], Configuration conf,  SecureResources resources) throws IOException {  *//创建DataNode对象，并准备必要的DataNode RPC Server对象* DataNode dn = *instantiateDataNode*(args, conf, resources);  if (dn != null) {  *//启动dataXceiverServer 和 ipcServer 服务* dn.runDatanodeDaemon();  }  return dn; } |

以上代码中instantiateDataNode创建返回了DataNode对象，并在创建DataNode的构造中初始化DataXceiver服务、HttpServer服务、DataNode PRC 服务及向NameNode注册并进行心跳汇报，然后再通过“dn.runDatanodeDaemon();”方法启动DataXceiver服务和DataXceiver服务用于接收客户端写数据和通信。

instantiateDataNode(args, conf, resources);实现代码如下:

|  |
| --- |
| public static DataNode instantiateDataNode(String args [], Configuration conf,  SecureResources resources) throws IOException {  ... ...  *//根据配置获取DataNode 数据存储位置*Collection<StorageLocation> dataLocations = *getStorageLocations*(conf);  ... ...  *//创建返回DataNode 对象*return *makeInstance*(dataLocations, conf, resources);  } |

makeInstance方法会携带DataNode 数据存储位置创建DataNode对象。makeInstance源码如下：

|  |
| --- |
| static DataNode makeInstance(Collection<StorageLocation> dataDirs,  Configuration conf, SecureResources resources) throws IOException {  *... ...*  *//检查数据目录可用*locations = storageLocationChecker.check(conf, dataDirs);  *... ...*  *//至少配置的一个数据目录可用就返回创建DataNode*return new DataNode(conf, locations, storageLocationChecker, resources);  } |

在DataNode 对象的构造中执行了startDataNode方法初始化各种服务及向NameNode注册信息。进入DataNode构造可以看到startDataNode方法：

|  |
| --- |
| DataNode(final Configuration conf,  final List<StorageLocation> dataDirs,  final StorageLocationChecker storageLocationChecker,  final SecureResources resources) throws IOException {  *... ...*  *//startDataNode中初始化各种服务及向NameNode 注册信息及保持心跳*startDataNode(dataDirs, resources);  *... ...*  } |

在StartDataNode方法中主要做了如下4个流程：

1. 初始化DataXceiver服务，该服务是Datanode接手客户端请求的核心组件。
2. 创建HttpServer并启动，方便用户通过WebUI访问DataNode。
3. 初始化DataNode Rpc 服务端
4. 获取NameNode RpcProxy代理
5. DataNode向NameNode注册
6. DataNode与NameNode周期心跳和block块汇报

详细源码如下：

|  |
| --- |
| void startDataNode(List<StorageLocation> dataDirectories,  SecureResources resources  ) throws IOException {  *... ...*  *//1.初始化DataXceiver服务,该服务是 DataNode 接收客户端请求的核心组件*initDataXceiver();  *//2.创建HttpServer 并启动，用户可以通过WebUI访问*startInfoServer();  *... ...*  *//3.初始化DataNode PRC 服务端，创建的IPC Server在DataNode对象创建完成后启动*initIpcServer();  *... ...*  *//4.DataNode 向 每个 NameNode 注册并进行周期心跳汇报（5）*blockPoolManager.refreshNamenodes(getConf());  *... ...*  *}* |

DataXceiver服务在数据上传部分讲解，下面结合源码介绍其他五个流程。

## **创建HttpServer**

startInfoServer()主要创建httpServer并启动，该服务启动后用户可以通过WebUi访问DataNode。源码如下：

|  |
| --- |
| private void startInfoServer()  throws IOException {  ... ...  httpServer = new DatanodeHttpServer(getConf(), this, httpServerChannel);httpServer.start();  ... ...  } |

其中DatanodeHttpServer构造如下：

|  |
| --- |
| public DatanodeHttpServer(final Configuration conf,  final DataNode datanode,  final ServerSocketChannel externalHttpChannel)  throws IOException {  ... ...  *//hostName方法中设置了hostname和ip 9870*HttpServer2.Builder builder = new HttpServer2.Builder()  .setName("datanode")  .setConf(confForInfoServer)  .setACL(new AccessControlList(conf.get(*DFS\_ADMIN*, " ")))  *//设置节点和端口* .hostName(*getHostnameForSpnegoPrincipal*(confForInfoServer))  .addEndpoint(URI.*create*("http://localhost:" + proxyPort))  .setFindPort(true);  .... ...  this.infoServer = builder.build();  ... ...  this.infoServer.start();  ... ...  } |

## **初始化DataNode Rpc服务**

initIpcServer()方法中进行DataNode Rpc 服务端的初始化，代码如下：

|  |
| --- |
| private void initIpcServer() throws IOException {  InetSocketAddress ipcAddr = NetUtils.*createSocketAddr*(  ... ...  ipcServer = new RPC.Builder(getConf())  .setProtocol(ClientDatanodeProtocolPB.class)  .setInstance(service)  .setBindAddress(ipcAddr.getHostName())  .setPort(ipcAddr.getPort())  .setNumHandlers(  getConf().getInt(*DFS\_DATANODE\_HANDLER\_COUNT\_KEY*,  *DFS\_DATANODE\_HANDLER\_COUNT\_DEFAULT*)).setVerbose(false)  .setSecretManager(blockPoolTokenSecretManager).build();  ... ...  } |

关于 ipcServer 的启动是在DataNode对象创建完成后，执行“dn.runDatanodeDaemon()”方法中执行的。具体源码位于DataNode.createDataNode方法中：

|  |
| --- |
| public static DataNode createDataNode(String args[], Configuration conf,  SecureResources resources) throws IOException {  *//创建DataNode对象，并准备必要的DataNode RPC Server对象* DataNode dn = *instantiateDataNode*(args, conf, resources);  if (dn != null) {  *//启动dataXceiverServer 和 ipcServer 服务* dn.runDatanodeDaemon();  }  return dn; } |

## **获取NameNode Rpc代理**

startDataNode中的“blockPoolManager.refreshNamenodes(getConf())”代码主要负责DataNode向每个NameNode注册并进行心跳汇报，refreshNamenodes实现源码如下：

|  |
| --- |
| void refreshNamenodes(Configuration conf)  throws IOException {  ... ...  *//获取所有NameNode地址*newAddressMap =  DFSUtil.*getNNServiceRpcAddressesForCluster*(conf);*//从 dfs.namenode.lifeline.rpc-address 属性中获取地址，用于 DataNode 向 NameNode 发送心跳和块汇报等信息，默认该属性为空。*newLifelineAddressMap =  DFSUtil.*getNNLifelineRpcAddressesForCluster*(conf);  ... ...  *//以上是获取到NameNode通信地址，然后向每个NameNode注册*doRefreshNamenodes(newAddressMap, newLifelineAddressMap);  *//以上是获取到NameNode通信地址，然后向每个NameNode注册*doRefreshNamenodes(newAddressMap, newLifelineAddressMap);  } |

以上代码中，newAddressMap是获取所有NameNode节点地址，newLifelineAddressMap是从dfs.namenode.lifeline.rpc-address 配置属性中获取地址，默认该属性没有配置。newLifelineAddressMap如果配置了，该获取的地址主要用于DataNode向NameNode发送心跳和block块汇报。

最后执行“doRefreshNamenodes”方法，向每个NameNode节点通信并进行注册。doRefreshNamenodes源码如下：

|  |
| --- |
| private void doRefreshNamenodes(  Map<String, Map<String, InetSocketAddress>> addrMap,  Map<String, Map<String, InetSocketAddress>> lifelineAddrMap)  throws IOException {  ... ...  *//返回 BPOfferService 对象，该对象中bpServices 中包含于所有 NameNode通信的BPServiceActor对象*BPOfferService bpos = createBPOS(nsToAdd, nnIds, addrs,  lifelineAddrs);  ... ...offerServices.add(bpos);  .... ...  *//遍历 offerServices，启动服务*startAll();  } |

以上代码中，createBPOS方法返回 BPOfferService 对象，该对象中bpServices 中包含于所有 NameNode通信的BPServiceActor对象。createBPOS方法如下：

|  |
| --- |
| protected BPOfferService createBPOS(  final String nameserviceId,  List<String> nnIds,  List<InetSocketAddress> nnAddrs,  List<InetSocketAddress> lifelineNnAddrs) {  *//返回 BPOfferService 对象，该对象中bpServices 中包含于所有 NameNode通信的BPServiceActor对象* return new BPOfferService(nameserviceId, nnIds, nnAddrs, lifelineNnAddrs,  dn); } |

“new BPOfferService”中进行每个NameNode的遍历，并将负责与NameNode通信的BPServiceActor对象加入到BPOfferService.bpServices这个集合中。new BPOfferService实现如下：

|  |
| --- |
| BPOfferService(  final String nameserviceId, List<String> nnIds,  List<InetSocketAddress> nnAddrs,  List<InetSocketAddress> lifelineNnAddrs,  DataNode dn) {  ... ...  for (int i = 0; i < nnAddrs.size(); ++i) {  *// BPServiceActor 负责 与NameNode 通信：发送心跳到NameNode* this.bpServices.add(new BPServiceActor(nameserviceId, nnIds.get(i),  nnAddrs.get(i), lifelineNnAddrs.get(i), this)); }  ... ...  } |

注意：BPServiceActor是一个线程，后续会执行相关的run方法，并且在new BPServiceActor对象时，会初始化Scheduler对象，该对象会周期性向NameNode汇报DataNode心跳信息，new BPServiceActor实现源码如下：

|  |
| --- |
| class BPServiceActor implements Runnable {  ... ...  BPServiceActor(String serviceId, String nnId, InetSocketAddress nnAddr,  InetSocketAddress lifelineNnAddr, BPOfferService bpos) {  ... ...  *//创建 scheduler 对象，该scheduler对象负责后续周期向NameNode汇报心跳* *//传递第一个参数默认为dfs.heartbeat.interval 参数为3s*scheduler = new Scheduler(dnConf.heartBeatInterval,  dnConf.getLifelineIntervalMs(), dnConf.blockReportInterval,  dnConf.outliersReportIntervalMs);  ... ...  ) |

以上代码中scheduler对象负责后续周期向NameNode汇报心跳，默认3秒。

回到doRefreshNamenodes方法的startAll()方法，在该方法中可以看到遍历offerServices中的BPOfferService对象并调用对应的start方法，在start方法中会循环遍历bpServices中的每个BPServiceActor进行启动。具体源码如下：  
startAll()方法如下：

|  |
| --- |
| synchronized void startAll() throws IOException {  ... ...  for (BPOfferService bpos : offerServices) {  bpos.start(); }  ... ...  } |

以上bpos.start()方法源码如下：

|  |
| --- |
| void start() {  for (BPServiceActor actor : bpServices) {  *//BPServiceActor 是一个线程，调用run 方法* actor.start();  } } |

当调用BPServiceActor 对象的start方法时，由于BPServiceActor 是一个线程所以会执行到对应的BPServiceActor.run方法，在该run方法中进行连接NameNode注册并与NameNode保持心跳。BPServiceActor.run方法源码如下：

|  |
| --- |
| public void run() {  ... ...  *//获取NameNode RpcProxy 并连接NameNode进行信息注册*connectToNNAndHandshake();  ... ...  *//DataNode 与NameNode 保持心跳*offerService();  ... ...  } |

connectToNNAndHandshake()方法的具体实现如下：

|  |
| --- |
| private void connectToNNAndHandshake() throws IOException {  ... ...  *//连接NameNode ,返回bpNamenode为DatanodeProtocolClientSideTranslatorPB对象，该对象中有NameNode Rpc代理*bpNamenode = dn.connectToNN(nnAddr);  *//第一步：获取NameNode管理的命名空间，一个集群中可能存在多个NS*NamespaceInfo nsInfo = retrieveNamespaceInfo();    *//第二步：向NameNode进行注册*register(nsInfo);  } |

以上代码中：“bpNamenode = dn.connectToNN(nnAddr)”连接NameNode ,返回bpNamenode为DatanodeProtocolClientSideTranslatorPB对象，该对象中有NameNode Rpc代理,通过NameNode Rpc代理可以远程调用NameNode的方法。ConnectToNN源码实现如下：

|  |
| --- |
| DatanodeProtocolClientSideTranslatorPB connectToNN(  InetSocketAddress nnAddr) throws IOException {  return new DatanodeProtocolClientSideTranslatorPB(nnAddr, getConf()); } |

DatanodeProtocolClientSideTranslatorPB的构造中创建了NameNode rpcProxy代理对象：

|  |
| --- |
| public DatanodeProtocolClientSideTranslatorPB(InetSocketAddress nameNodeAddr,  Configuration conf) throws IOException {  RPC.*setProtocolEngine*(conf, DatanodeProtocolPB.class,  ProtobufRpcEngine2.class);  UserGroupInformation ugi = UserGroupInformation.*getCurrentUser*();  *//获取NameNode远程代理对象，* rpcProxy = *createNamenode*(nameNodeAddr, conf, ugi); } |

以上代码的“createNamenode”中获取NameNode 远程代理对象源码如下：

|  |
| --- |
| private static DatanodeProtocolPB createNamenode(  InetSocketAddress nameNodeAddr, Configuration conf,  UserGroupInformation ugi) throws IOException {  *//这里返回了 RpcProtocol 对象为DatanodeProtocolPB，该对象表示获取到NameNode远程通信代理对象，DataNode与NameNode通信远程调用方法都在DatanodeProtocolPB 接口中* return RPC.*getProxy*(DatanodeProtocolPB.class,  RPC.*getProtocolVersion*(DatanodeProtocolPB.class), nameNodeAddr, ugi,  conf, NetUtils.*getSocketFactory*(conf, DatanodeProtocolPB.class)); } |

可以看到该代码中RPC.getProxy(...)传入的第一个参数是DatanodeProtocolPB.class，表示远程调用NameNode所有方法的接口就是此接口，进入DatanodeProtocolPB.class可以看到有@ProtocolInfo注解：

|  |
| --- |
| @ProtocolInfo(  protocolName = "org.apache.hadoop.hdfs.server.protocol.DatanodeProtocol",   protocolVersion = 1)@InterfaceAudience.Privatepublic interface DatanodeProtocolPB extends  DatanodeProtocolService.BlockingInterface { } |

以上代码中，@ProtocolInfo注解指定协议的相关信息，protocolName参数指定了协议的名称，protocolVersion参数指定了协议的版本号。指定的 org.apache.hadoop.hdfs.server.protocol.DatanodeProtocol 是一个Java接口，定义了用于DataNode与NameNode之间通信的协议。通常，它定义了一系列方法，这些方法由DataNode实现，用于与NameNode进行通信和执行各种操作。DatanodeProtocolPB也是一个java接口，它实际上是 DatanodeProtocol 接口的一种实现方式。

综上所述，后面通过获取到的NameNode RpcProxy代理对象进行远程调用NameNode相应方法时实际上会找到DatanodeProtocol 接口的实现类，通过查询源码可以看到NameNodeRpcServer类实现了DatanodeProtocol 接口：

|  |
| --- |
| public class NameNodeRpcServer implements NamenodeProtocols {  *...*  *}*  *... ...*  public interface NamenodeProtocols  extends ClientProtocol,  DatanodeProtocol,  DatanodeLifelineProtocol,  NamenodeProtocol,  RefreshAuthorizationPolicyProtocol,  ReconfigurationProtocol,  RefreshUserMappingsProtocol,  RefreshCallQueueProtocol,  GenericRefreshProtocol,  GetUserMappingsProtocol,  HAServiceProtocol { } |

所以，当在DataNode端通过NameNode的RpcProxy 远程调用到NameNode相应方法时，会调用到 NameNodeRpcServer 类中相应的实现方法。

## **Datanode向NameNode注册**

继续回到BPSercviceActor.connectToNNAndHandshake方法中,源码如下：

|  |
| --- |
| private void connectToNNAndHandshake() throws IOException {  ... ...  *//连接NameNode ,返回bpNamenode为DatanodeProtocolClientSideTranslatorPB对象，该对象中有NameNode Rpc代理*bpNamenode = dn.connectToNN(nnAddr);  *//第一步：获取NameNode管理的命名空间，一个集群中可能存在多个NS*NamespaceInfo nsInfo = retrieveNamespaceInfo();    *//第二步：向NameNode进行注册*register(nsInfo);  } |

“register(nsInfo)”方法实现DataNode向NameNode进行注册。源码实现如下：

|  |
| --- |
| void register(NamespaceInfo nsInfo) throws IOException {  ... ...  *//准备注册DataNode的信息对象：DatanodeRegistration*DatanodeRegistration newBpRegistration = bpos.createRegistration();  ... ...  *//向NameNode 注册DataNode，调用的registerDatanode 方法位于 NameNodeRpcServer.java 类中*newBpRegistration = bpNamenode.registerDatanode(newBpRegistration);  ... ...  } |

“bpNamenode.registerDatanode”的实现如下：

|  |
| --- |
| public DatanodeRegistration registerDatanode(DatanodeRegistration registration  ) throws IOException {  ... ...  *//rpcProxy是NameNode远程代理，调用 registerDatanode 方法在*resp = rpcProxy.registerDatanode(*NULL\_CONTROLLER*, builder.build());  ... ...  } |

以上代码中 “rpcProxy”对象是NameNode远程代理，调用的registerDatanode 方法位于 NameNodeRpcServer.java 类中。

NameNodeRpcServer类中的registerDatanode方法实现源码如下：

|  |
| --- |
| *//DataNode向NameNode 进行注册*@Override *// DatanodeProtocol*public DatanodeRegistration registerDatanode(DatanodeRegistration nodeReg)  throws IOException {  checkNNStartup();  verifySoftwareVersion(nodeReg);  namesystem.registerDatanode(nodeReg);  return nodeReg; } |

以上代码中“namesystem.registerDatanode(nodeReg);”实现如下：

|  |
| --- |
| void registerDatanode(DatanodeRegistration nodeReg) throws IOException {  writeLock();  try {  blockManager.registerDatanode(nodeReg);  } finally {  writeUnlock("registerDatanode");  } } |

“blockManager.registerDatanode(nodeReg);”实现源码如下：

|  |
| --- |
| public void registerDatanode(DatanodeRegistration nodeReg)  throws IOException {  assert namesystem.hasWriteLock();  datanodeManager.registerDatanode(nodeReg);  bmSafeMode.checkSafeMode(); } |

以上代码中“registerDatanode”方法中实现了DataNode向NameNode注册：

|  |
| --- |
| public void registerDatanode(DatanodeRegistration nodeReg)  throws DisallowedDatanodeException, UnresolvedTopologyException {  ... ...  String hostname = dnAddress.getHostName();*//获取DataNode hostname*String ip = dnAddress.getHostAddress();*//获取DataNode ip*  ... ...  nodeReg.setIpAddr(ip); nodeReg.setPeerHostName(hostname);  ... ...  *//创建DataNode Description*DatanodeDescriptor nodeDescr   = new DatanodeDescriptor(nodeReg, NetworkTopology.*DEFAULT\_RACK*);  ... ...  *// register new datanode*addDatanode(nodeDescr);*//注册新的DataNode*  ... ...  *//注册也看成一次心跳检测*heartbeatManager.addDatanode(nodeDescr);  ... ...  } |

以上 addDatanode实现如下：

|  |
| --- |
| void addDatanode(final DatanodeDescriptor node) {  ... ...  synchronized(this) {  *//host2DatanodeMap 存储了主机名（host）与数据节点之间的映射关系*  *//datanodeMap 存储了数据节点（DataNode）的 UUID 与对应的 DatanodeDescriptor 对象之间的映射关系*  *//将DataNode 加入到 datanodeMap，如果先前有该DataNode节点信息那么先从host2DatanodeMap中移除，后续重新再加入正确节点映射信息* host2DatanodeMap.remove(datanodeMap.put(node.getDatanodeUuid(), node)); }  ... ...  } |

“datanodeMap.put(node.getDatanodeUuid(), node)”代码就是将DataNode信息加入到dataNodeMap对象中完成DataNode向NameNode注册。

host2DatanodeMap 存储了主机名（host）与数据节点之间的映射关系，而host2DatanodeMap.remove(datanodeMap.put(node.getDatanodeUuid(), node))，表示如果先前host2DatanodeMap中已有对应的DataNode信息，先从host2DatanodeMap中移除，后续再重新加入到host2DatanodeMap中。

## **DataNode与NameNode周期心跳及block块汇报**

回到BpServiceActor中run方法中，除了连接NameNode向DataNode进行注册外，后续还会周期性向NameNode进行心跳和block块汇报。run方法实现如下：

|  |
| --- |
| public void run() {  ... ...  *//获取NameNode RpcProxy 并连接NameNode进行信息注册*connectToNNAndHandshake();  ... ...  *//DataNode 与NameNode 保持心跳*offerService();  ... ...  } |

offerService实现代码如下:

|  |
| --- |
| private void offerService() throws Exception {  ... ...  *//判断是否应该进行心跳，默认周期3秒*final boolean sendHeartbeat = scheduler.isHeartbeatDue(startTime);  ... ...  *//向NameNode发送心跳信息*resp = sendHeartBeat(requestBlockReportLease);  ... ...  } |

以上“final boolean sendHeartbeat = scheduler.isHeartbeatDue(startTime);”代码中会看到每隔3秒进行一次心跳信息汇报。

sendHeartBeat实现源码如下：

|  |
| --- |
| HeartbeatResponse sendHeartBeat(boolean requestBlockReportLease)  throws IOException {  ... ...  *//进行下次心跳时间设置，设置的值为当前时间加上3s*scheduler.scheduleNextHeartbeat();  ... ...  *//DataNode向NameNode 发送心跳汇报block信息，sendHeartbeat方法*HeartbeatResponse response = bpNamenode.sendHeartbeat(bpRegistration,  reports,  dn.getFSDataset().getCacheCapacity(),  dn.getFSDataset().getCacheUsed(),  dn.getXmitsInProgress(),  dn.getActiveTransferThreadCount(),  numFailedVolumes,  volumeFailureSummary,  requestBlockReportLease,  slowPeers,  slowDisks);  ... ... |

“scheduler.scheduleNextHeartbeat();”设置下次进行心跳的时间。

bpNamenode.sendHeartbeat(...)最终调用到NameNodeRpcServer中的sendHeartbeat方法进行block块上报。
