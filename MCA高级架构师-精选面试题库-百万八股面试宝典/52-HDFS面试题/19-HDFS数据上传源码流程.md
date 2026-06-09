当我们向HDFS中写入数据时，自己编写代码如下：

|  |
| --- |
| public class WriteDataToHDFS {  public static void main(String[] args) throws IOException, InterruptedException {  Configuration conf = new Configuration();    *//创建FileSystem对象* FileSystem fs = FileSystem.*get*(URI.*create*("hdfs://node1:8020/"),conf,"root");   *//创建HDFS文件路径* Path path = new Path("/test.txt");  FSDataOutputStream out = fs.create(path);   *//向HDFS中写出数据* out.write("hello zs".getBytes());  } } |

客户端向HDFS中写入数据会首先与NameNode进行通信获取数据写入HDFS中对应哪些DataNode节点，然后在客户端将数据划分成packet传输到HDFS各个DataNode节点上。这个过程会经过初始化DFSClient、连接NameNode创建目录、建立与DataNode连接、向DataNode中上传数据等步骤，下面分别对以上各个阶段源码进行介绍。

## **创建文件系统及初始化DFSClient**

操作HDFS前需要创建DFSClient对象，该对象中持有与NameNode通信的NameNode Rpc Proxy。DFSClient对象的创建是执行“FileSystem fs = FileSystem.get(URI.create("hdfs://node1:8020/"),conf,"root");”代码中FileSystem.get(...) 方法时创建的。

FileSystem.get(...)具体源码如下：

|  |
| --- |
| public static FileSystem get(final URI uri, final Configuration conf,  final String user) throws IOException, InterruptedException {  String ticketCachePath =  conf.get(CommonConfigurationKeys.*KERBEROS\_TICKET\_CACHE\_PATH*);  UserGroupInformation ugi =  UserGroupInformation.*getBestUGI*(ticketCachePath, user);  return ugi.doAs(new PrivilegedExceptionAction<FileSystem>() {  @Override  public FileSystem run() throws IOException {  *//创建分布式文件系统及初始化DFSClient* return *get*(uri, conf);  }  });  } |

以上代码“get(uri,conf)”又调用到FileSystem.get(...)方法源码如下：

|  |
| --- |
| public static FileSystem get(URI uri, Configuration conf) throws IOException {  ... ...  *//创建分布式文件系统及初始化DFSClient* return *CACHE*.get(uri, conf); } |

“CACHE.get(uri，conf)”又调用到如下源码：

|  |
| --- |
| FileSystem get(URI uri, Configuration conf) throws IOException{  Key key = new Key(uri, conf);  *//创建分布式文件系统及初始化DFSClient* return getInternal(uri, conf, key); } |

在getInternal方法中最终执行”createFileSystem(url,conf)”创建分布式文件系统及初始化DFSClient。

getInternal(...)源码如下：

|  |
| --- |
| private FileSystem getInternal(URI uri, Configuration conf, Key key)  throws IOException{  ... ...  *//创建分布式文件系统及初始化DFSClient*fs = *createFileSystem*(uri, conf);  ... ...  } |

在createFileSystem方法中获取了初始化HDFS文件系统的类org.apache.hadoop.hdfs.DistributedFileSystem并初始化了DFSClient对象。createFileSystem具体源码如下：

|  |
| --- |
| private static FileSystem createFileSystem(URI uri, Configuration conf)  throws IOException {  *... ...*  *//创建的 class 为 org.apache.hadoop.hdfs.DistributedFileSystem*Class<? extends FileSystem> clazz =  *getFileSystemClass*(uri.getScheme(), conf);  *//初始化分布式文件系统*FileSystem fs = ReflectionUtils.*newInstance*(clazz, conf);  *... ...*  *//调用到 DistributedFileSystem 中的 initialize方法，初始化创建DFSClient*fs.initialize(uri, conf);  *... ...*  } |

以上代码中在执行“FileSystem fs = ReflectionUtils.newInstance(clazz, conf);”初始化文件系统时，clazz为“org.apache.hadoop.hdfs.DistributedFileSystem”具体可见getFileSystemClass(uri.getScheme(), conf)源码，如下：

|  |
| --- |
| public static Class<? extends FileSystem> getFileSystemClass(String scheme,  Configuration conf) throws IOException {  ... ...  *//将 FileSystem 抽象类的所有实现类中的 schema和对应实现类放入 SERVICE\_FILE\_SYSTEMS 对象中**loadFileSystems*();  ... ...  *//从配置中获取 fs.hdfs.impl*String property = "fs." + scheme + ".impl";  ... ...  *//如果配置文件中没有配置 fs.hdfs.impl 那么获取的clazz 为 null*clazz = (Class<? extends FileSystem>) conf.getClass(  property, null);  ... ...  *//获取的clazz 为 org.apache.hadoop.hdfs.DistributedFileSystem*clazz = *SERVICE\_FILE\_SYSTEMS*.get(scheme);  ... ...  return clazz; } |

以上代码中“loadFileSystems()”会将 FileSystem 抽象类的所有实现类中的 schema和对应实现类放入 SERVICE\_FILE\_SYSTEMS 对象中，loadFileSystems()实现源码如下:

|  |
| --- |
| private static void loadFileSystems() {  ... ...  *//ServiceLoader.load(FileSystem.class)会加载所有 FileSystem 实现类中的schema信息*ServiceLoader<FileSystem> serviceLoader = ServiceLoader.*load*(FileSystem.class);  ... ...  *//将所有文件系统的 schema信息存入 SERVICE\_FILE\_SYSTEMS Map中**SERVICE\_FILE\_SYSTEMS*.put(fs.getScheme(), fs.getClass());  ... ...  } |

getFileSystemClass方法中首先从配置文件中获取“fs.hdfs.impl”配置的HDFS类，默认在HDFS中没有配置该属性，该属性也没有默认值，所以得到clazz为null，进而执行“clazz = SERVICE\_FILE\_SYSTEMS.get(scheme);”得到clazz为“org.apache.hadoop.hdfs.DistributedFileSystem”,所以，最终在FileSystem.createFileSystem(...)中得到的fs为“org.apache.hadoop.hdfs.DistributedFileSystem”。

FileSystem.createFileSystem(...)中“fs.initialize(uri, conf);”代码执行时，这里的fs就是“org.apache.hadoop.hdfs.DistributedFileSystem”类，找到DistributedFileSystem.initialize实现与源码如下：​

|  |
| --- |
| public void initialize(URI uri, Configuration conf) throws IOException {  ... ...  *//创建DFSClient，传入的URI 为NameNode URI*initDFSClient(uri, conf);  ... ...  } |

initDFSClient(...) 主要创建DFSClient对象并在创建DFSClient对象时创建了NameNode Rpc Proxy对象并赋值给其属性namenode，方便后续客户端和NameNode进行通信。具体“initDFSClient(uri, conf);”实现源码如下：

|  |
| --- |
| void initDFSClient(URI theUri, Configuration conf) throws IOException {  *//创建DFSClient ,传入了 NameNode的URI* this.dfs = new DFSClient(theUri, conf, statistics); } |

new DFSClient构造如下：

|  |
| --- |
| public DFSClient(URI nameNodeUri, Configuration conf,  FileSystem.Statistics stats) throws IOException {  this(nameNodeUri, null, conf, stats); } |

this调用到DFSClient实现,其中创建了NameNode Rpc Proxy 并赋值给了namenode属性。

|  |
| --- |
| public DFSClient(URI nameNodeUri, ClientProtocol rpcNamenode,  Configuration conf, FileSystem.Statistics stats) throws IOException {  ... ...  *//获取NameNode Rpc Proxy*proxyInfo = NameNodeProxiesClient.*createProxyWithLossyRetryHandler*(conf,  nameNodeUri, ClientProtocol.class, numResponseToDrop,  nnFallbackToSimpleAuth);  ... ...  *//给DFSClient中的namenode 赋值 NameNode的Rpc Proxy对象*this.namenode = proxyInfo.getProxy();  ... ...  } |

后续客户端可以通过DFSClient.namenode获取到NameNode的RPC Proxy对象与NameNode进行通信。

## **连接NN创建目录**

在自己编写的代码执行到“FSDataOutputStream out = fs.create(path)”时，会在HDFS中创建目录并准备dataQueue，dataQueue用于客户端数据传输队列，并最后反馈FSDataOutputStream对象，该对象用于向HDFS中写数据。

跟进fs.create(...) 源码一层层对象包装，会发现该create方法最终调到 DistributedFileSystem.create(...)方法，其源码如下：

|  |
| --- |
| @Overridepublic FSDataOutputStream create(Path f, FsPermission permission,  boolean overwrite, int bufferSize, short replication, long blockSize,  Progressable progress) throws IOException {  *//返回 FSDataOutputStream 对象* return this.create(f, permission,  overwrite ? EnumSet.*of*(CreateFlag.*CREATE*, CreateFlag.*OVERWRITE*)  : EnumSet.*of*(CreateFlag.*CREATE*), bufferSize, replication,  blockSize, progress, null); } |

以上create方法会继续调用到DistributedFileSystem.create(...)方法，只是参数不同，源码如下：

|  |
| --- |
| public FSDataOutputStream create(final Path f, final FsPermission permission,  final EnumSet<CreateFlag> cflags, final int bufferSize,  final short replication, final long blockSize,  final Progressable progress, final ChecksumOpt checksumOpt)  throws IOException {  ... ...  return new FileSystemLinkResolver<FSDataOutputStream>() {  @Override  public FSDataOutputStream doCall(final Path p) throws IOException {  *//执行dfs.create方法，最终调用到 DFSClient.create方法* final DFSOutputStream dfsos = dfs.create(getPathName(p), permission,  cflags, replication, blockSize, progress, bufferSize,  checksumOpt);  return safelyCreateWrappedOutputStream(dfsos);  }  ... ....  } |

以上代码执行dfs.create方法，最终调用到 DFSClient.create方法：

|  |
| --- |
| public DFSOutputStream create(String src, FsPermission permission,  EnumSet<CreateFlag> flag, short replication, long blockSize,  Progressable progress, int buffersize, ChecksumOpt checksumOpt)  throws IOException {  return create(src, permission, flag, true,  replication, blockSize, progress, buffersize, checksumOpt, null); } |

create方法又经过一些列参数包装，最终调用到如下源码：

|  |
| --- |
| public DFSOutputStream create(String src, FsPermission permission,  EnumSet<CreateFlag> flag, boolean createParent, short replication,  long blockSize, Progressable progress, int buffersize,  ChecksumOpt checksumOpt, InetSocketAddress[] favoredNodes,  String ecPolicyName, String storagePolicy)  throws IOException {  *... ...*  *//newStreamForCreate中获取到NameNoae Rpc Proxy 代理对象并连接创建目录，然后启动DataStreamer 线程用于接收客户端上传的packet*final DFSOutputStream result = DFSOutputStream.*newStreamForCreate*(this,  src, masked, flag, createParent, replication, blockSize, progress,  dfsClientConf.createChecksum(checksumOpt),  getFavoredNodesStr(favoredNodes), ecPolicyName, storagePolicy);  *... ...*  *}* |

在以上代码中，“DFSOutputStream.newStreamForCreate”中获取到NameNoae Rpc Proxy 代理对象并连接创建目录，然后启动DataStreamer 线程用于接收客户端上传的packet，并最终返回DFSOutputStream对象。

newStreamForCreate具体源码如下：

|  |
| --- |
| static DFSOutputStream newStreamForCreate(DFSClient dfsClient, String src,  FsPermission masked, EnumSet<CreateFlag> flag, boolean createParent,  short replication, long blockSize, Progressable progress,  DataChecksum checksum, String[] favoredNodes, String ecPolicyName,  String storagePolicy)  throws IOException {  *... ...*  *//dfsClient.namenode 就是 NameNode Rpc Proxy 对象，调用的create方法，调用到NameNodeRpcServer.create方法* *//这里连接到NameNode进行了文件创建*stat = dfsClient.namenode.create(src, masked, dfsClient.clientName,  new EnumSetWritable<>(flag), createParent, replication,  blockSize, *SUPPORTED\_CRYPTO\_VERSIONS*, ecPolicyName,  storagePolicy);  *... ...*  *//普通写文件策略，out对象是DFSOutputStream* *// 该DFSOutputStream构造中会创建DataStreamer 线程，负责向HDFS中写数据*out = new DFSOutputStream(dfsClient, src, stat,  flag, progress, checksum, favoredNodes, true);  *... ...*  *//启动DataStreamer 线程 ,运行run方法*out.start();  *... ...*  } |

以上代码“dfsClient.namenode.create(...)”方法会通过NameNode Rpc Proxy 对象调用到NameNodeRpcServer.create方法，然后在HDFS中经过一些目录和权限判断来创建对应目录。NameNodeRpcServer.create源码如下：

|  |
| --- |
| @Override *// ClientProtocol //客户端创建文件*public HdfsFileStatus create(String src, FsPermission masked,  String clientName, EnumSetWritable<CreateFlag> flag,  boolean createParent, short replication, long blockSize,  CryptoProtocolVersion[] supportedVersions, String ecPolicyName,  String storagePolicy)  throws IOException {  *... ...*  *//去HDFS中创建文件*status = namesystem.startFile(src, perm, clientName, clientMachine,  flag.get(), createParent, replication, blockSize, supportedVersions,  ecPolicyName, storagePolicy, cacheEntry != null);  *... ...*  *}* |

以上startFile源码如下：

|  |
| --- |
| HdfsFileStatus startFile(String src, PermissionStatus permissions,  String holder, String clientMachine, EnumSet<CreateFlag> flag,  boolean createParent, short replication, long blockSize,  CryptoProtocolVersion[] supportedVersions, String ecPolicyName,  String storagePolicy, boolean logRetryCache) throws IOException {  *... ...*  *//创建文件目录*status = startFileInt(src, permissions, holder, clientMachine, flag,  createParent, replication, blockSize, supportedVersions, ecPolicyName,  storagePolicy, logRetryCache);  *... ...*  *}* |

startFileInt实现源码如下：

|  |
| --- |
| private HdfsFileStatus startFileInt(String src,  PermissionStatus permissions, String holder, String clientMachine,  EnumSet<CreateFlag> flag, boolean createParent, short replication,  long blockSize, CryptoProtocolVersion[] supportedVersions,  String ecPolicyName, String storagePolicy, boolean logRetryCache)  throws IOException {  *... ...*  *//创建文件目录*stat = FSDirWriteFileOp.*startFile*(this, iip, permissions, holder,  clientMachine, flag, createParent, replication, blockSize, feInfo,  toRemoveBlocks, shouldReplicate, ecPolicyName, storagePolicy,  logRetryCache);  *... ...*  } |

以上代码中startFile实现如下：

|  |
| --- |
| static HdfsFileStatus startFile(  FSNamesystem fsn, INodesInPath iip,  PermissionStatus permissions, String holder, String clientMachine,  EnumSet<CreateFlag> flag, boolean createParent,  short replication, long blockSize,  FileEncryptionInfo feInfo, INode.BlocksMapUpdateInfo toRemoveBlocks,  boolean shouldReplicate, String ecPolicyName, String storagePolicy,  boolean logRetryEntry)  throws IOException {  *... ...*  *//创建文件*iip = *addFile*(fsd, parent, iip.getLastLocalName(), permissions,  replication, blockSize, holder, clientMachine, shouldReplicate,  ecPolicyName, storagePolicy);  *... ...*  *}* |

addFile中最终会执行“newiip = fsd.addINode(existing, newNode, permissions.getPermission());”向HDFS中添加目录信息。

## **启动DataStreamer线程**

继续回到DFSOutputStream.newStreamForCreate(...)部分，newStreamForCreate具体源码如下：

|  |
| --- |
| static DFSOutputStream newStreamForCreate(DFSClient dfsClient, String src,  FsPermission masked, EnumSet<CreateFlag> flag, boolean createParent,  short replication, long blockSize, Progressable progress,  DataChecksum checksum, String[] favoredNodes, String ecPolicyName,  String storagePolicy)  throws IOException {  *... ...*  *//dfsClient.namenode 就是 NameNode Rpc Proxy 对象，调用的create方法，调用到NameNodeRpcServer.create方法* *//这里连接到NameNode进行了文件创建*stat = dfsClient.namenode.create(src, masked, dfsClient.clientName,  new EnumSetWritable<>(flag), createParent, replication,  blockSize, *SUPPORTED\_CRYPTO\_VERSIONS*, ecPolicyName,  storagePolicy);  *... ...*  *//普通写文件策略，out对象是DFSOutputStream* *// 该DFSOutputStream构造中会创建DataStreamer 线程，负责向HDFS中写数据*out = new DFSOutputStream(dfsClient, src, stat,  flag, progress, checksum, favoredNodes, true);  *... ...*  *//启动DataStreamer 线程 ,运行run方法*out.start();return out;  } |

当向NameNode连接创建目录后，会执行“new DFSOutputStream(dfsClient, src, stat, flag, progress, checksum, favoredNodes, true);”创建DFSOutputStream对象并最终返回，在创建该对象的构造中同时创建了DataStreamer对象并赋值给streamer属性，DataStreamer对象负责后续接收客户端上传数据并将数据发送pipeline方式发送到DataNode上，该对象为一个线程，创建DFSOutputStream对象完成后会执行“out.start()”方法进行启动。

“new DFSOutputStream”实现源码如下：

|  |
| --- |
| protected DFSOutputStream(DFSClient dfsClient, String src,  HdfsFileStatus stat, EnumSet<CreateFlag> flag, Progressable progress,  DataChecksum checksum, String[] favoredNodes, boolean createStreamer) {  ... ...  *//计算写入数据包的大小，默认每个packetSize大小为64kb*computePacketChunkSize(dfsClient.getConf().getWritePacketSize(),  bytesPerChecksum);  ... ...  *//创建 DataStreamer 对象负责 向HDFS中写入数据*streamer = new DataStreamer(stat, null, dfsClient, src, progress,  checksum, cachingStrategy, byteArrayManager, favoredNodes,  addBlockFlags);  ... ...  } |

可见在DFSOutputStream创建同时获取了后续写入数据时packet大小（默认为64K）并给其streamer属性初始化了DataStreamer值（DataStreamer是一个线程）。当创建好 DFSOutputStream对象后赋值给out对象，当执行“out.start();”方法时，实际上执行的就是streamer.start,由于DataStreamer是一个线程，所以最终调用到其中的run方法。

DataStreamer.run方法源码如下：

|  |
| --- |
| public void run() {  ... ...  synchronized (dataQueue) {  *// wait for a packet to be sent.*  *//等待packet 放入到 dataQueue,packet当客户端写入数据时才会放入到dataQueue* while ((!shouldStop() && dataQueue.isEmpty()) || doSleep) {  ... ...  *//dataQueue 中目前没有数据，进入等待状态*dataQueue.wait(timeout);  ... ...  }  ... ...  *//等待数据包并构建写入DN管道，向DN中写入数据*  } |

以上代码中 dataQueue是一个Linkedlist<DFSPacket>对象，该对象会一直处于while循环中等待客户端上传文件的packet，当有数据放入该LinkedList后，会从该对象中获取一个个的packet写出到DN中。

## **向dataQueue队列中写入packet**

向HDFS写入数据是通过执行自己编写代码“out.write("hello zs".getBytes());”实现的。out对象为DFSOutputStream对象，所以write方法优先找该对象中的write方法，但是发现DFSOutputStream对象中没有write方法，所以找到DFSOutputStream对象的父类FSOutputSummer.write方法，故“out.write("hello zs".getBytes());”最终执行到FSOutputSummer.write方法实现，其源码如下：​

|  |
| --- |
| @Overridepublic synchronized void write(int b) throws IOException {  buf[count++] = (byte)b;  if(count == buf.length) {  *//刷新缓冲区，写出数据* flushBuffer();  } } |

以上代码中flushBuffer()实现源码如下：

|  |
| --- |
| protected synchronized void flushBuffer() throws IOException {  *//向packet中写入数据* flushBuffer(false, true); } |

flushBuffer方法实现源码如下：

|  |
| --- |
| protected synchronized int flushBuffer(boolean keep,  boolean flushPartial) throws IOException {  ... ...  *// 调用writeChecksumChunks方法将缓冲区的数据写入到输出流，并进行校验和*writeChecksumChunks(buf, 0, lenToFlush);  ... ...  } |

以上writeChecksumChunks(...)方法主要就是对写入buffer数据进行校验和生成并与数据一并写入packet。writeChecksumChunks实现如下：​

|  |
| --- |
| *// 为给定的数据块生成校验和，并将输出块和校验和写入底层输出流*private void writeChecksumChunks(byte b[], int off, int len)throws IOException {  ... ...  *//根据数据块的大小，计算数据块的校验和*sum.calculateChunkedSums(b, off, len, checksum, 0);  .. ...  *//将当前数据块和对应的校验块写入到底层输出流中*writeChunk(b, off + i, chunkLen, checksum, ckOffset,  getChecksumSize());  ... ...  } |

以上代码中writeChunk(...)方法最终会调用到DFSOutputStream.writeChunk(...)实现，其源码如下：

|  |
| --- |
| protected synchronized void writeChunk(byte[] b, int offset, int len,  byte[] checksum, int ckoff, int cklen) throws IOException {  ... ...  *// 将校验和写入当前数据包*currentPacket.writeChecksum(checksum, ckoff, cklen);*// 将数据块写入当前数据包*currentPacket.writeData(b, offset, len);  ... ...  *// 如果数据包已满，则将其排队等待传输*enqueueCurrentPacketFull();  ... ...  } |

以上代码中，随着数据写入到packet中数据量达到默认64K时，会将packet写入到对应的dataQueue中。

enqueueCurrentPacketFull()方法实现源码如下：

|  |
| --- |
| synchronized void enqueueCurrentPacketFull() throws IOException {  *LOG*.debug("enqueue full {}, src={}, bytesCurBlock={}, blockSize={},"  + " appendChunk={}, {}", currentPacket, src, getStreamer()  .getBytesCurBlock(), blockSize, getStreamer().getAppendChunk(),  getStreamer());  *//当前数据包排队等待传输* enqueueCurrentPacket();  adjustChunkBoundary();  endBlock(); } |

以上enqueueCurrentPacket()方法实现原理如下：

|  |
| --- |
| void enqueueCurrentPacket() throws IOException {  *//当前数据包排队等待传输*getStreamer().waitAndQueuePacket(currentPacket);  currentPacket = null; } |

waitAndQueuePacket()方法实现如下：

|  |
| --- |
| void waitAndQueuePacket(DFSPacket packet) throws IOException {  synchronized (dataQueue) {  ... ...  *//将当前packet 放入 dataQueue 中*queuePacket(packet);  ... ...  } |

queuePacket(...)实现代码如下：

|  |
| --- |
| void queuePacket(DFSPacket packet) {  synchronized (dataQueue) {  if (packet == null) return;  packet.addTraceParent(Tracer.*getCurrentSpan*());  *//将packet 加入到dataQueue LinkedList 中* dataQueue.addLast(packet);  lastQueuedSeqno = packet.getSeqno();  *LOG*.debug("Queued {}, {}", packet, this);  *//notifyAll()方法通知所有正在等待dataQueue对象锁的线程，告诉它们数据队列已经有数据包放入，可以继续执行* dataQueue.notifyAll();  } } |

以上代码中“dataQueue.addLast(packet);”就是将packet 加入到dataQueue LinkedList 中，当执行到“dataQueue.notifyAll();”时，会通知所有正在等待dataQueue对象锁的线程，告诉它们数据队列已经有数据包放入，可以继续执行。

## **设置副本写入策略源码**

回到DataStreamer.run方法源码，该部分代码已经在向HDFS中创建目录时已经执行。如下：

|  |
| --- |
| public void run() {  ... ...  synchronized (dataQueue) {  *// wait for a packet to be sent.*  *//等待packet 放入到 dataQueue,packet当客户端写入数据时才会放入到dataQueue* while ((!shouldStop() && dataQueue.isEmpty()) || doSleep) {  ... ...  *//dataQueue 中目前没有数据，进入等待状态*dataQueue.wait(timeout);  ... ...  }  ... ...  *//获取待发送的数据包*one = dataQueue.getFirst(); *// regular data packet*  ... ...  *//构建写数据管道，通过管道连接到第一个DataNode，该DN将数据发送到管道的第二个DN，以此类推* *//nextBlockOutputStream 方法中连接NameNode申请写入数据的DataNode节点及副本分布策略，并设置客户端与第一个Block块所在的节点的socket连接*setPipeline(nextBlockOutputStream());  ... ...  *//将packet 以流的方式写入到DataNode节点*sendPacket(one);  ... ...  *//等待所有ack*waitForAllAcks();  ... ...  } |

以上代码大体逻辑为：当dataQueue中有packet后，会执行“one = dataQueue.getFirst()”获取packet包并通过“sendPacket(one);”将packet数据写出到DataNode节点。

客户端向HDFS DataNode写入数据时，默认有3个副本，并且各个DataNode节点之间写出数据都是以pipeline方式依次传递到各个DataNode节点，所以在执行“sendPacket(one);”写出数据前，会执行“setPipeline(nextBlockOutputStream());”方法构建写数据管道，通过管道连接到第一个DataNode，将packet数据写入该节点，然后由第二个DataNode依次再将packet传递到第三个DataNode节点，副本多的依次类推。其中“nextBlockOutputStream()”方法中会连接NameNode申请写入数据的DataNode节点及副本分布策略，并设置客户端与第一个Block块所在的节点的socket连接，方便后续将数据写入到对应的DataNode节点。

nextBlockOutputStream()方法源码如下：

|  |
| --- |
| protected LocatedBlock nextBlockOutputStream() throws IOException {  ... ...  *//locateFollowingBlock方法中向NameNode申请副本写入的DN节点信息并设置副本策略*lb = locateFollowingBlock(  excluded.length > 0 ? excluded : null, oldBlock);block.setCurrentBlock(lb.getBlock());  ... ...  *//获取Block块所在的所有节点信息*nodes = lb.getLocations();  ... ...  *//连接到节点列表中的第一个 DataNode 节点并建立客户端与DataNode节点的socket连接，方便后续将数据写入到DataNode*success = createBlockOutputStream(nodes, nextStorageTypes, nextStorageIDs,  0L, false);  ... ...  } |

以上代码中“locateFollowingBlock( excluded.length > 0 ? excluded : null, oldBlock);”代码中会向NameNode申请副本写入DN节点的信息并设置副本分布策略。

locateFollowingBlock(...)源码如下：

|  |
| --- |
| private LocatedBlock locateFollowingBlock(DatanodeInfo[] excluded,  ExtendedBlock oldBlock) throws IOException {  *//向NameNode 添加block 块信息* return DFSOutputStream.*addBlock*(excluded, dfsClient, src, oldBlock,  stat.getFileId(), favoredNodes, addBlockFlags); } |

以上代码中addBlock方法中会向NameNode申请block分布策略及写入DN节点信息。DFSOutputStream.addBlock(...)实现源码如下：

|  |
| --- |
| static LocatedBlock addBlock(DatanodeInfo[] excludedNodes,  DFSClient dfsClient, String src, ExtendedBlock prevBlock, long fileId,  String[] favoredNodes, EnumSet<AddBlockFlag> allocFlags)  throws IOException {  *... ...*  *//向向NameNode申请block分布策略及写入DN节点信息*return dfsClient.namenode.addBlock(src, dfsClient.clientName, prevBlock,  excludedNodes, fileId, favoredNodes, allocFlags);  *... ...*  } |

以上代码中dfsClient.namenode获取到NameNode Rpc Proxy，所以addBlock方法最终会调用到NameNodeRpcServer.addBlock(...)方法。NameNodeRpcServer.addBlock(...)源码如下：

|  |
| --- |
| *//客户端写入数据向NameNode 申请block位置*@Overridepublic LocatedBlock addBlock(String src, String clientName,  ExtendedBlock previous, DatanodeInfo[] excludedNodes, long fileId,  String[] favoredNodes, EnumSet<AddBlockFlag> addBlockFlags)  throws IOException {  *//检查NameNode是否启动* checkNNStartup();  *//getAdditionalBlock方法设置副本存储节点策略，返回的 LocatedBlock 对象中包含 block写入数据的DN节点* LocatedBlock locatedBlock = namesystem.getAdditionalBlock(src, fileId,  clientName, previous, excludedNodes, favoredNodes, addBlockFlags);  if (locatedBlock != null) {  metrics.incrAddBlockOps();  }  return locatedBlock; } |

以上代码“namesystem.getAdditionalBlock(...)”源码如下：

|  |
| --- |
| LocatedBlock getAdditionalBlock(  String src, long fileId, String clientName, ExtendedBlock previous,  DatanodeInfo[] excludedNodes, String[] favoredNodes,  EnumSet<AddBlockFlag> flags) throws IOException {  ... ...  *//为新数据块选择DataNode 节点，有几个副本选择几个节点*DatanodeStorageInfo[] targets = FSDirWriteFileOp.*chooseTargetForNewBlock*(  blockManager, src, excludedNodes, favoredNodes, flags, r);  ... ...  } |

以上代码中chooseTargetForNewBlock(...)会为block找到存储DN节点，源码如下：

|  |
| --- |
| static DatanodeStorageInfo[] chooseTargetForNewBlock(  BlockManager bm, String src, DatanodeInfo[] excludedNodes,  String[] favoredNodes, EnumSet<AddBlockFlag> flags,  ValidateAddBlockResult r) throws IOException {  ... ...  *// 为新数据块选择目标数据节点* return bm.chooseTarget4NewBlock(src, r.numTargets, clientNode,  excludedNodesSet, r.blockSize,  favoredNodesList, r.storagePolicyID,  r.blockType, r.ecPolicy, flags); } |

chooseTarget4NewBlock(...)中会为block选择目标数据节点：

|  |
| --- |
| public DatanodeStorageInfo[] chooseTarget4NewBlock(final String src,  final int numOfReplicas, final Node client,  final Set<Node> excludedNodes,  final long blocksize,  final List<String> favoredNodes,  final byte storagePolicyID,  final BlockType blockType,  final ErasureCodingPolicy ecPolicy,  final EnumSet<AddBlockFlag> flags) throws IOException {  ... ...  *//存放数据副本的节点数组*final DatanodeStorageInfo[] targets = blockplacement.chooseTarget(src,  numOfReplicas, client, excludedNodes, blocksize,   favoredDatanodeDescriptors, storagePolicy, flags);  ... ...  *//返回数据存放节点数组*return targets;  } |

以上代码“blockplacement.chooseTarget(...)”方法经过一层层对象封装，最终调用到“BlockPlacementPolicyDefault.chooseTarget”方法，该方法实现源码如下：

|  |
| --- |
| private DatanodeStorageInfo[] chooseTarget(int numOfReplicas,  Node writer,  List<DatanodeStorageInfo> chosenStorage,  boolean returnChosenNodes,  Set<Node> excludedNodes,  long blocksize,  final BlockStoragePolicy storagePolicy,  EnumSet<AddBlockFlag> addBlockFlags,  EnumMap<StorageType, Integer> sTypes) {  ... ...  *// 获取每个机架上的最大节点数*int[] result = getMaxNodesPerRack(chosenStorage.size(), numOfReplicas);  ... ...  List<DatanodeStorageInfo> results = null;  ... ...  *//这里的results 与 chosenStorage 完全相同，但是目前没有数据*results = new ArrayList<>(chosenStorage);*//设置副本分布并返回第一个副本要写入的DN节点*localNode = chooseTarget(numOfReplicas, writer, excludedNodes,  blocksize, maxNodesPerRack, results, avoidStaleNodes,  storagePolicy, EnumSet.*noneOf*(StorageType.class), results.isEmpty(),  sTypes);  ... ...  return getPipeline(  (writer != null && writer instanceof DatanodeDescriptor) ? writer  : localNode,  results.toArray(new DatanodeStorageInfo[results.size()]));  } |

进入以上代码中“chooseTarget”方法，源码如下：

|  |
| --- |
| private Node chooseTarget(final int numOfReplicas,  Node writer,  final Set<Node> excludedNodes,  final long blocksize,  final int maxNodesPerRack,  final List<DatanodeStorageInfo> results,  final boolean avoidStaleNodes,  final BlockStoragePolicy storagePolicy,  final EnumSet<StorageType> unavailableStorages,  final boolean newBlock,  EnumMap<StorageType, Integer> storageTypes) {  *... ...*  *//准备多副本写入的DN节点分布，返回的writer为第一个副本要写入的DN节点*writer = chooseTargetInOrder(numOfReplicas, writer, excludedNodes, blocksize,  maxNodesPerRack, results, avoidStaleNodes, newBlock, storageTypes);  *... ...*  return writer;  } |

以上代码中“chooseTargetInOrder”中实现副本分布并返回第一个副本要写入的DN节点。“chooseTargetInOrder”源码如下：

|  |
| --- |
| protected Node chooseTargetInOrder(int numOfReplicas,   Node writer,  final Set<Node> excludedNodes,  final long blocksize,  final int maxNodesPerRack,  final List<DatanodeStorageInfo> results,  final boolean avoidStaleNodes,  final boolean newBlock,  EnumMap<StorageType, Integer> storageTypes)  throws NotEnoughReplicasException {  *// 计算结果列表的大小，默认初始 results 为0，result集合表示副本所在的节点* final int numOfResults = results.size();  *// 如果结果列表为空* if (numOfResults == 0) {  *// 选择本地节点作为第一个副本存储位置，并向result中加入节点* DatanodeStorageInfo storageInfo = chooseLocalStorage(writer,  excludedNodes, blocksize, maxNodesPerRack, results, avoidStaleNodes,  storageTypes, true);   *//writer第一个副本要写出的DataNode节点* writer = (storageInfo != null) ? storageInfo.getDatanodeDescriptor()  : null;   *//减去一个副本后，如果为0则返回，writer,否则不返回，继续* if (--numOfReplicas == 0) {  return writer;  }  }  *//第一个副本所在DN节点* final DatanodeDescriptor dn0 = results.get(0).getDatanodeDescriptor();   if (numOfResults <= 1) {  *//选择远程机架存放第二个副本* chooseRemoteRack(1, dn0, excludedNodes, blocksize, maxNodesPerRack,  results, avoidStaleNodes, storageTypes);  if (--numOfReplicas == 0) {  *//writer第一个副本要写出的DataNode节点* return writer;  }  }   if (numOfResults <= 2) {  *//第二个副本所在DN节点* final DatanodeDescriptor dn1 = results.get(1).getDatanodeDescriptor();  if (clusterMap.isOnSameRack(dn0, dn1)) {*//如果dn0与dn1是同一机架，第三个副本选择不同机架* chooseRemoteRack(1, dn0, excludedNodes, blocksize, maxNodesPerRack,  results, avoidStaleNodes, storageTypes);  } else if (newBlock){*//如果是新块，选择与dn1 第二个副本所在节点相同的机架上放第三个副本* chooseLocalRack(dn1, excludedNodes, blocksize, maxNodesPerRack,  results, avoidStaleNodes, storageTypes);  } else {*//随机选择一台节点存储第3个副本* chooseLocalRack(writer, excludedNodes, blocksize, maxNodesPerRack,  results, avoidStaleNodes, storageTypes);  }  if (--numOfReplicas == 0) {  *//writer第一个副本要写出的DataNode节点* return writer;  }  }  *//大于3个副本，随机选择节点存放副本* chooseRandom(numOfReplicas, NodeBase.*ROOT*, excludedNodes, blocksize,  maxNodesPerRack, results, avoidStaleNodes, storageTypes);  *//writer第一个副本要写出的DataNode节点* return writer; } |

“chooseTargetInOrder”方法代码逻辑为block 副本找到存储节点的策略，然后返回block所在的第一个节点，首先第一个block存储在本机，第二个block存储在远程机架，第三个副本存储时先判断是否第一个副本和第二个副本是否在同一机架，如果在同一机架，那么第三个副本选择不同机架进行存储，否则选择与第二个副本相同机架的随机节点进行存储。最终该方法返回存储第一个副本的DataNode节点。

## **客户端与DataNode建立socket通信**

在DataNode启动源码部分，DataNode.initDataXceiver()方法进行初始化DataXceiver服务,该服务是 DataNode 接收客户端请求的核心组件，其核心实现源码如下：*​*

|  |
| --- |
| private void initDataXceiver() throws IOException {  ... ...  *//TcpPeerServer 对象用于接收来自客户端的传输流量*TcpPeerServer tcpPeerServer;  ... ...  *//DataXceiverServer 是一个线程*xserver = new DataXceiverServer(tcpPeerServer, getConf(), this);*//创建DataXceiverServer的后台线程，创建好DataNode后会启动*this.dataXceiverServer = new Daemon(threadGroup, xserver);  ... ...  } |

在DataNode.crateDataNode(...)方法中，当DataNode对象创建完成后，当执行“dn.runDatanodeDaemon();”时会运行DataXceiverServer对象的run方法，DataXceiverServer.run方法实现源码如下：

|  |
| --- |
| public void run() {  ... ...  *// 接受客户端的连接请求*peer = peerServer.accept();  ... ...  *//创建线程并传入peer参数，然后并启动，会调用到DataXceiver.run 方法*new Daemon(datanode.threadGroup,  DataXceiver.*create*(peer, datanode, this))  .start();  ... ...  } |

以上代码中我们可以看到“peerServer.accept()”一直接受来自客户端传输数据socket通信，并且“new Daemon(datanode.threadGroup,DataXceiver.create(peer, datanode, this)).start();”代码中创建了DataXceiver线程并启动，该线程主要从DataXceiverServer中读取socket传入数据并将数据写入到DataNode节点磁盘。

下面继续回到DataStreamer.nextBlockOutputStream()源码中，查看客户端与DataNode节点建立的连接。

DataStreamer.nextBlockOutputStream()方法源码如下：

|  |
| --- |
| protected LocatedBlock nextBlockOutputStream() throws IOException {  ... ...  *//locateFollowingBlock方法中向NameNode申请副本写入的DN节点信息并设置副本策略*lb = locateFollowingBlock(  excluded.length > 0 ? excluded : null, oldBlock);block.setCurrentBlock(lb.getBlock());  ... ...  *//获取Block块所在的所有节点信息*nodes = lb.getLocations();  ... ...  *//连接到节点列表中的第一个 DataNode 节点并建立客户端与DataNode节点的socket连接，方便后续将数据写入到DataNode*success = createBlockOutputStream(nodes, nextStorageTypes, nextStorageIDs,  0L, false);  ... ...  } |

前面执行完locateFollowingBlock(...)方法，获取到了数据应该写往的DataNode节点后，后续会执行“createBlockOutputStream(nodes, nextStorageTypes, nextStorageIDs,0L, false);”方法与第一个写出的DataNode节点建立连接，createBlockOutputStream(...)实现部分源码如下：

|  |
| --- |
| boolean createBlockOutputStream(DatanodeInfo[] nodes,  StorageType[] nodeStorageTypes, String[] nodeStorageIDs,  long newGS, boolean recoveryFlag) {  ... ...  *// 创建客户端用于数据传输管道的Socket，这里传入的nodes[0]就是第一个DataNode节点*s = *createSocketForPipeline*(nodes[0], nodes.length, dfsClient);  ... ...  *//当输出流有数据时，通过socket将数据写出到DataNode中*  *... ...*  } |

以上“createSocketForPipeline(nodes[0], nodes.length, dfsClient);”代码就是获取第一个写出数据的block所在的DataNode节点，并建立socket连接。createSocketForPipeline源码如下：

|  |
| --- |
| static Socket createSocketForPipeline(final DatanodeInfo first,  final int length, final DFSClient client) throws IOException {  ... ...  *//获取第一个 DataNode节点 socket地址*final InetSocketAddress isa = NetUtils.*createSocketAddr*(dnAddr);  ... ...  *//客户端连接上 DataNode，DataNode 启动着**DataXceiverServer 服务，该服务启动后一直会接收客户端scoket 通信*NetUtils.*connect*(sock, isa, client.getRandomLocalInterfaceAddr(),  conf.getSocketTimeout());  ... ...  return sock; } |

## **向Datanode中写入数据**

回到 DataStreamr.createBlockOutputStream(...)方法中，核心源码如下：

|  |
| --- |
| boolean createBlockOutputStream(DatanodeInfo[] nodes,  StorageType[] nodeStorageTypes, String[] nodeStorageIDs,  long newGS, boolean recoveryFlag) {  ... ...  *// 创建客户端用于数据传输管道的Socket，这里传入的nodes[0]就是第一个DataNode节点*s = *createSocketForPipeline*(nodes[0], nodes.length, dfsClient);  ... ...  *// 获取未缓冲的输出流和输入流*OutputStream unbufOut = NetUtils.*getOutputStream*(s, writeTimeout);InputStream unbufIn = NetUtils.*getInputStream*(s, readTimeout);  ... ...  *//包装 输出流 unbufOut 到 out 对象中*out = new DataOutputStream(new BufferedOutputStream(unbufOut,  DFSUtilClient.*getSmallBufferSize*(dfsClient.getConfiguration())));  ... ...  *//DataNode 启动着DataXceiverServer 服务，该服务启动后一直会接收客户端scoket 通信*new Sender(out).writeBlock(blockCopy, nodeStorageTypes[0], accessToken,  dfsClient.clientName, nodes, nodeStorageTypes, null, bcs,  nodes.length, block.getNumBytes(), bytesSent, newGS,  checksum4WriteBlock, cachingStrategy.get(), isLazyPersistFile,  (targetPinnings != null && targetPinnings[0]), targetPinnings,  nodeStorageIDs[0], nodeStorageIDs);  ... ...  } |

当写出数据的输出流out中有数据时,会通过“new Sender(out).writeBlock(...)”方法将数据发送到DataNode节点，writeBlock(...)实现具体源码如下：

|  |
| --- |
| public void writeBlock(final ExtendedBlock blk,  final StorageType storageType,  final Token<BlockTokenIdentifier> blockToken,  final String clientName,  final DatanodeInfo[] targets,  final StorageType[] targetStorageTypes,  final DatanodeInfo source,  final BlockConstructionStage stage,  final int pipelineSize,  final long minBytesRcvd,  final long maxBytesRcvd,  final long latestGenerationStamp,  DataChecksum requestedChecksum,  final CachingStrategy cachingStrategy,  final boolean allowLazyPersist,  final boolean pinning,  final boolean[] targetPinnings,  final String storageId,  final String[] targetStorageIds) throws IOException {  ... ...  *//包装socket 流和 操作类型 “WRITE\_BLOCK” ,通过socket 发送到DataNode 节点* *send*(out, Op.*WRITE\_BLOCK*, proto.build()); } |

以上send方法会将数据发送到DataNode 中，DataNode启动的DataXceiverServer 服务会接收客户端socket通信。

再次回到DataXceiverServer.run()方法源码中：

|  |
| --- |
| public void run() {  *... ...*  *// 接受客户端的连接请求*peer = peerServer.accept();  *... ...*  *//创建线程并传入peer参数，然后并启动，会调用到DataXceiver.run 方法*new Daemon(datanode.threadGroup,  DataXceiver.*create*(peer, datanode, this))  .start();  *... ...*  *}* |

“new Daemon(datanode.threadGroup,DataXceiver.create(peer, datanode, this)).start();”代码中会将接受到客户端的连接包装到DataXceiver线程对象中并启动，在DataXceiver.run方法中会对从客户端接收到的数据进行写出到DataNode磁盘处理。

DataXceiver.run方法源码如下：

|  |
| --- |
| public void run() {  ... ...  *// 初始化操作对象*Op op = null;  ... ...  *// 初始化输入流*InputStream input = socketIn;  ... ...  *//读取客户端传入的数据给输入流赋值*input = new BufferedInputStream(saslStreams.in,  smallBufferSize);  ... ...  *// 初始化DataXceiver的输入流 ，就是将 input 流赋值给了Receiver 中的 in 属性，后续使用*super.initialize(new DataInputStream(input));  ... ...  *//读取输入数据*op = readOp();  ... ...  *//处理读取过来的数据流*processOp(op);  ... ...  } |

以上代码会将从客户端中接收过来的数据包装成数据输入流，最终执行“processOp(op);”写出到DataNode节点磁盘上。

processOp(op)实现源码如下,op默认从客户端传入类型值为“WRITE\_BLOCK”：

|  |
| --- |
| protected final void processOp(Op op) throws IOException {  ... ...  *//从客户端获取过来的操作属性为 “WRITE\_BLOCK”*case *WRITE\_BLOCK*:  *//向DataNode中写入Block块操作* opWriteBlock(in);  break;  ... ...  } |

opWriteBlock(in)实现代码如下：

|  |
| --- |
| private void opWriteBlock(DataInputStream in) throws IOException {  ... ...  *// 调用writeBlock方法处理写入块操作*writeBlock(PBHelperClient.*convert*(proto.getHeader().getBaseHeader().getBlock()),  PBHelperClient.*convertStorageType*(proto.getStorageType()),  PBHelperClient.*convert*(proto.getHeader().getBaseHeader().getToken()),  proto.getHeader().getClientName(),  targets,  PBHelperClient.*convertStorageTypes*(proto.getTargetStorageTypesList(), targets.length),  PBHelperClient.*convert*(proto.getSource()),  *fromProto*(proto.getStage()),  proto.getPipelineSize(),  proto.getMinBytesRcvd(), proto.getMaxBytesRcvd(),  proto.getLatestGenerationStamp(),  *fromProto*(proto.getRequestedChecksum()),  (proto.hasCachingStrategy() ?  *getCachingStrategy*(proto.getCachingStrategy()) :  CachingStrategy.*newDefaultStrategy*()),  (proto.hasAllowLazyPersist() ? proto.getAllowLazyPersist() : false),  (proto.hasPinning() ? proto.getPinning(): false),  (PBHelperClient.*convertBooleanList*(proto.getTargetPinningsList())),  proto.getStorageId(),  proto.getTargetStorageIdsList().toArray(new String[0]));  ... ...  } |

以上 writeBlock最终调用到“DataXceiver.writeBlock(...)”方法，其源码实现如下：

|  |
| --- |
| public void writeBlock(...){  ... ...  *// 创建blockReceiver 并赋值给 DataXceiver.blockReceiver，后续使用到该对象写出数据到磁盘*setCurrentBlockReceiver(getBlockReceiver(block, storageType, in,  peer.getRemoteAddressString(),  peer.getLocalAddressString(),  stage, latestGenerationStamp, minBytesRcvd, maxBytesRcvd,  clientname, srcDataNode, datanode, requestedChecksum,  cachingStrategy, allowLazyPersist, pinning, storageId));  ... ...  *//发送数据到下游DN节点，对于下游DataNode节点，仍然要走一遍当前节点的流程，形成DataNode 依次向后写出数据*new Sender(mirrorOut).writeBlock(originalBlock, targetStorageTypes[0],  blockToken, clientname, targets, targetStorageTypes,  srcDataNode, stage, pipelineSize, minBytesRcvd, maxBytesRcvd,  latestGenerationStamp, requestedChecksum, cachingStrategy,  allowLazyPersist, targetPinnings[0], targetPinnings,  targetStorageId, targetStorageIds);  ... ...  *//receiveBlock 会接收packets 将数据写出到磁盘*blockReceiver.receiveBlock(mirrorOut, mirrorIn, replyOut, mirrorAddr,  dataXceiverServer.getWriteThrottler(), targets, false);  ... ...  } |

以上代码中“new Sender(mirrorOut).writeBlock(...)”这部分代码是将写入到该DataNode节点的packet数据继续写往下个DataNode节点，如果block有多个副本，都是在下一个DataNode节点向后续DN节点发送写出数据。

最终执行“blockReceiver.receiveBlock(...)”代码将数据写出到磁盘中，receiverBlock(...)实现关键源码如下：

|  |
| --- |
| void receiveBlock(  DataOutputStream mirrOut, *// output to next datanode* DataInputStream mirrIn, *// input from next datanode* DataOutputStream replyOut, *// output to previous datanode* String mirrAddr, DataTransferThrottler throttlerArg,  DatanodeInfo[] downstreams,  boolean isReplaceBlock) throws IOException {  ... ...  *//receivePacket负责接收上游的packet*while (receivePacket() >= 0) { */\* Receive until the last packet \*/* }  ... ...  } |

以上代码中receivePacket()会一直接受从客户端发送过来的packet并写入到DataNode节点磁盘，直到客户端数据传输完毕。

reveiverPacket()关键源码实现如下：

|  |
| --- |
| private int receivePacket() throws IOException {  ... ...  *//将数据写出到DataNode节点磁盘*streams.writeDataToDisk(dataBuf.array(),  startByteToDisk, numBytesToDisk);  ... ...  } |
