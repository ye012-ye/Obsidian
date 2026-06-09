数据 从HDFS中读取数据代码如下：

|  |
| --- |
| public class ReadDataFromHDFS {  public static void main(String[] args) throws IOException, InterruptedException {  Configuration conf = new Configuration();   *//创建FileSystem对象* FileSystem fs = FileSystem.*get*(URI.*create*("hdfs://node1:8020/"),conf,"root");   *//创建HDFS文件路径* Path path = new Path("/test.txt");  FSDataInputStream in = fs.open(path);    *//读取HDFS中数据* BufferedReader br = new BufferedReader(new InputStreamReader(in));  String newLine = "";  while((newLine = br.readLine()) != null) {  System.*out*.println(newLine);  }   *//关闭流对象* br.close();  in.close();  } } |

HDFS中数据读取源码相对简单，客户端从HDFS中获取文件数据时，首先会向NameNode获取文件相关的block信息，然后连接各个Datanode以流方式读取数据即可。

## **连接NameNode获取block信息**

HDFS读取数据代码中，执行到“FileSystem fs = FileSystem.get(URI.create("hdfs://node1:8020/"),conf,"root");”代码时，也会创建DFSClient，参考上传数据代码。当代码执行到fs.open(...)时，其中fs为DistributedFileSystem对象，所以open方法最终调用到DistributedFileSystem.open方法，其源码如下：

|  |
| --- |
| @Override *//客户端读取HDFS中数据*public FSDataInputStream open(Path f, final int bufferSize)  throws IOException {  ... ...  return new FileSystemLinkResolver<FSDataInputStream>() {  @Override  public FSDataInputStream doCall(final Path p) throws IOException {  *//执行dfs.open 方法，返回DFSInputStream对象* final DFSInputStream dfsis =  dfs.open(getPathName(p), bufferSize, verifyChecksum);  try {  return dfs.createWrappedInputStream(dfsis);  } catch (IOException ex){  dfsis.close();  throw ex;  }  }  @Override  public FSDataInputStream next(final FileSystem fs, final Path p)  throws IOException {  return fs.open(p, bufferSize);  } }.resolve(this, absF);  ... ...  } |

以上代码中，“dfs.open(...)”方法最终返回读取数据对象DFSInputStream。

“dfs.open(...)”源码如下：

|  |
| --- |
| public DFSInputStream open(String src, int buffersize, boolean verifyChecksum)  throws IOException {  checkOpen();  *// Get block info from namenode* try (TraceScope ignored = newPathTraceScope("newDFSInputStream", src)) {  *//从NameNode节点上获取Block信息* LocatedBlocks locatedBlocks = getLocatedBlocks(src, 0);  *//连接DataNode节点读取数据* return openInternal(locatedBlocks, src, verifyChecksum);  } } |

以上代码，其中“getLocatedBlocks(src, 0);”方法会连接NameNode节点上获取读取文件相关Block信息，openInternal(...)方法中将获取过来的LocatedBlocks对象（该对象中属性List<LocatedBlock> blocks表示读取文件的所有blockInfo信息）封装到DFSInputStream对象中并返回。

getLocatedBlocks源码如下：

|  |
| --- |
| public LocatedBlocks getLocatedBlocks(String src, long start)  throws IOException {  *//从NameNode 获取文件block信息* return getLocatedBlocks(src, start, dfsClientConf.getPrefetchSize()); } |

以上代码“getLocatedBlocks(...)”源码如下：

|  |
| --- |
| @VisibleForTestingpublic LocatedBlocks getLocatedBlocks(String src, long start, long length)  throws IOException {  try (TraceScope ignored = newPathTraceScope("getBlockLocations", src)) {  *//从NameNode 获取文件block信息* return *callGetBlockLocations*(namenode, src, start, length);  } } |

以上代码中“callGetBlockLocations(...)” 传入NameNode Rpc Proxy 对象，后续通过该对象连接NameNode。其源码如下：

|  |
| --- |
| static LocatedBlocks callGetBlockLocations(ClientProtocol namenode,  String src, long start, long length)  throws IOException {  try {  *//从NameNode 获取文件block信息* return namenode.getBlockLocations(src, start, length);  } catch(RemoteException re) {  throw re.unwrapRemoteException(AccessControlException.class,  FileNotFoundException.class,  UnresolvedPathException.class);  } } |

“namenode.getBlockLocations(src, start, length)”最终调用到NameNodeRpcServer.getBlockLocations(...)方法。

回到DFSClient.open()方法中，最终通过执行“return openInternal(locatedBlocks, src, verifyChecksum);”返回DFSInputStream对象。

## **客户端通过socket连接DataNode**

当从HDFS中通过流读取数据时，会将fs.open(...)方法返回的DFSInputStream对象经过一层层包装形成BufferedReader，该对象读取数据时最终调用到DFSInputStream.read(...)方法，其源码如下：

|  |
| --- |
| @Overridepublic synchronized int read() throws IOException {  if (oneByteBuf == null) {  oneByteBuf = new byte[1];  }  *//读取数据* int ret = read(oneByteBuf, 0, 1);  return (ret <= 0) ? -1 : (oneByteBuf[0] & 0xff); } |

以上Read方法实现源码如下：

|  |
| --- |
| @Overridepublic synchronized int read(@Nonnull final byte buf[], int off, int len)  throws IOException {  validatePositionedReadArgs(pos, buf, off, len);  if (len == 0) {  return 0;  }  ReaderStrategy byteArrayReader =  new ByteArrayStrategy(buf, off, len, readStatistics, dfsClient);  *//传入的是 ByteArrayStrategy* return readWithStrategy(byteArrayReader); } |

以上代码中，在最后返回的“return readWithStrategy(byteArrayReader);”代码中传入了ByteArrayStrategy对象，该对象表示客户端以ByteArray方式从HDFS DataNode中读取数据。

readWithStrategy(...)方法实现源码如下：

|  |
| --- |
| protected synchronized int readWithStrategy(ReaderStrategy strategy)  throws IOException {  ... ...  *// 如果当前位置小于文件长度*if (pos < getFileLength()) {  if (pos > blockEnd || currentNode == null) {  *// 根据LocateBlocks列表生成BlockReader对象，在BlockReader中实现连接DataNode节点并准备接受数据的流对象。* *// 返回的currentNode 为block所在期望的DataNode*currentNode = blockSeekTo(pos); }  ... ...  *//从socket流中读取数据，使用到blockSeekTo 方法中从DataNode 获取数据的 in 流对象*int result = readBuffer(strategy, realLen, corruptedBlocks);  ... ...  *//返回读取的结果*return result;  } |

以上代码中核心代码为 “blockSeekTo(...)”,该方法会根据LocateBlocks列表生成BlockReader对象，在BlockReader中实现连接DataNode节点并准备接受数据的流对象，返回的currentNode 为block所在期望的DataNode。

最终在“int result = readBuffer(strategy, realLen, corruptedBlocks);”代码中会使用到接收DataNode返回数据的流对象，将数据从DataNode节点接受过来。

下面先看“blockSeekTo(...)”源码实现，看看客户端如何连接上DataNode节点建立读取数据的连接对象。blockSeekTo(...)源码如下：

|  |
| --- |
| private synchronized DatanodeInfo blockSeekTo(long target)  throws IOException {  *... ...*  *//选择block所在DataNode的第一个节点信息*chosenNode = retval.info;  *//选择block所在DataNode的第一个节点 addr*InetSocketAddress targetAddr = retval.addr;  *... ...*  *//getBlockReader方法中与对应的DataNode节点进行连接并准备好接受从DataNode 返回的数据流的对象*blockReader = getBlockReader(targetBlock, offsetIntoBlock,  targetBlock.getBlockSize() - offsetIntoBlock, targetAddr,  storageType, chosenNode);  *... ...*  return chosenNode; } |

以上代码“getBlockReader(...)”的实现源码如下：

|  |
| --- |
| protected BlockReader getBlockReader(LocatedBlock targetBlock,  long offsetInBlock, long length, InetSocketAddress targetAddr,  StorageType storageType, DatanodeInfo datanode) throws IOException {  *... ...*  *// 最后执行build方法时，与DataNode节点建立连接，并准备接受数据的流对象* return new BlockReaderFactory(dfsClient.getConf()).  setInetSocketAddress(targetAddr).  setRemotePeerFactory(dfsClient).  setDatanodeInfo(datanode).  setStorageType(storageType).  setFileName(src).  setBlock(blk).  setBlockToken(accessToken).  setStartOffset(offsetInBlock).  setVerifyChecksum(verifyChecksum).  setClientName(dfsClient.clientName).  setLength(length).  setCachingStrategy(curCachingStrategy).  setAllowShortCircuitLocalReads(!shortCircuitForbidden).  setClientCacheContext(dfsClient.getClientContext()).  setUserGroupInformation(dfsClient.ugi).  setConfiguration(dfsClient.getConfiguration()).  build(); } |

以上代码最后指定build()方法中会执行“getRemoteBlockReaderFromDomain()”方法与DataNode节点建立连接，并准备接受数据的流对象。build()方法源码如下：

|  |
| --- |
| public BlockReader build() throws IOException {  ... ...  *//与DataNode节点建立连接，并准备接受数据的流对象*reader = getRemoteBlockReaderFromDomain();  ... ...  } |

getRemoteBlockReaderFromDomain()方法源码如下：

|  |
| --- |
| private BlockReader getRemoteBlockReaderFromDomain() throws IOException {  ... ...  *//与DataNode节点建立连接，并准备接受数据的流对象*blockReader = getRemoteBlockReader(peer);  ... ...  } |

最终“getRemoteBlockReader(...)”方法执行到BlockReaderRemote.newBlockReader方法中，其源码如下：

|  |
| --- |
| public static BlockReader newBlockReader(String file,  ExtendedBlock block,  Token<BlockTokenIdentifier> blockToken,  long startOffset, long len,  boolean verifyChecksum,  String clientName,  Peer peer, DatanodeID datanodeID,  PeerCache peerCache,  CachingStrategy cachingStrategy,  int networkDistance, Configuration configuration) throws IOException {  ... ...  *//准备发送到DataNode的输出流*final DataOutputStream out = new DataOutputStream(new BufferedOutputStream(  peer.getOutputStream(), bufferSize));  *//从DataNode节点上读取block数据，这里的readBlock方法中会通过send(...)方法将读取DN Block数据发送到DN节点上*new Sender(out).readBlock(block, blockToken, clientName, startOffset, len,  verifyChecksum, cachingStrategy);  *// peer.getInputStream() 为DataNode 端返回的数据流 ，相当于客户端的输入流，后续redaBuffer中会通过该in 对象进行数据读取*DataInputStream in = new DataInputStream(peer.getInputStream());  ... ...  } |

以上源码中“new Sender(out).readBlock(...)”中readBlock(...)方法中会通过“send(out, Op.READ\_BLOCK, proto);”方法，将读取Block的信息发送到DataNode节点。readBlock(...)实现核心源码如下：

|  |
| --- |
| public void readBlock(final ExtendedBlock blk,  final Token<BlockTokenIdentifier> blockToken,  final String clientName,  final long blockOffset,  final long length,  final boolean sendChecksum,  final CachingStrategy cachingStrategy) throws IOException {  ... ...  *//send 方法会发送给DataNode中的DataXceiver服务中，DataXceiver服务一直运行，* *send*(out, Op.*READ\_BLOCK*, proto); } |

在启动DataNode后，DataNode节点上一直启动DataXceiver服务，该服务会一直接受客户端与DataNode的通信。

最终，通过“DataInputStream in = new DataInputStream(peer.getInputStream());”来接收DataNode节点返回Block的数据流，后续会通过该in对象从DataNode中读取block数据。

## **DataNode返回block数据流**

找到DataNode节点的DataXceiver服务的run方法，其源码如下：

|  |
| --- |
| public void run() {  ... ...  *// 初始化操作对象*Op op = null;  ... ...  *// 初始化输入流*InputStream input = socketIn;  ... ...  *//读取客户端传入的数据给输入流赋值*input = new BufferedInputStream(saslStreams.in,  smallBufferSize);  ... ...  *//回复到客户端的socket流*socketOut = saslStreams.out;  ... ...  *// 初始化DataXceiver的输入流 ，就是将 input 流赋值给了Receiver 中的 in 属性，后续使用*super.initialize(new DataInputStream(input));  ... ...  *//读取输入数据*op = readOp();  ... ...  *//处理读取过来的数据流*processOp(op);  ... ...  } |

以上run方法为DataXceiver服务一直接受客户端发送过来的请求，当客户端执行“send(out, Op.READ\_BLOCK, proto);”该服务接受到请求后，会执行“processOp(op);”方法，该方法源码如下：

|  |
| --- |
| protected final void processOp(Op op) throws IOException {  ... ...  case *READ\_BLOCK*:  *//读取Block数据* opReadBlock();  break;  ... ...  } |

所以最终执行到“opReadBlock”方法，该方法源码如下：

|  |
| --- |
| private void opReadBlock() throws IOException {  ... ...  *//读取Block数据*readBlock(PBHelperClient.*convert*(proto.getHeader().getBaseHeader().getBlock()),  PBHelperClient.*convert*(proto.getHeader().getBaseHeader().getToken()),  proto.getHeader().getClientName(),  proto.getOffset(),  proto.getLen(),  proto.getSendChecksums(),  (proto.hasCachingStrategy() ?  *getCachingStrategy*(proto.getCachingStrategy()) :  CachingStrategy.*newDefaultStrategy*()));  ... ...  } |

以上代码中readBlock最终调用到DataXceiver.readBlock方法，源码如下：

|  |
| --- |
| public void readBlock(final ExtendedBlock block,  final Token<BlockTokenIdentifier> blockToken,  final String clientName,  final long blockOffset,  final long length,  final boolean sendChecksum,  final CachingStrategy cachingStrategy) throws IOException {  ... ...  *//将block数据以packet方法发送给客户端*read = blockSender.sendBlock(out, baseStream, null); *// send data*  ... ...  } |

以上代码中“sendBlock(...)”源码如下：

|  |
| --- |
| *//sendBlock() 用于读取数据块及其元数据，并将数据流式传输到客户端。*long sendBlock(DataOutputStream out, OutputStream baseStream,   DataTransferThrottler throttler) throws IOException {  final TraceScope scope = FsTracer.*get*(null)  .newScope("sendBlock\_" + block.getBlockId());  try {  *// 执行发送数据块的操作* return doSendBlock(out, baseStream, throttler);  } finally {  scope.close();  } } |

doSendBlock(...)源码如下：

|  |
| --- |
| private long doSendBlock(DataOutputStream out, OutputStream baseStream,  DataTransferThrottler throttler) throws IOException {  ... ...  while (endOffset > offset && !Thread.*currentThread*().isInterrupted()) {  manageOsCache();  *//循环发送packet数据到客户端* long len = sendPacket(pktBuf, maxChunksPerPacket, streamForSendChunks,  transferTo, throttler);  offset += len;  totalRead += len + (numberOfChunks(len) \* checksumSize);  seqno++; }  ... ...  } |

以上代码中“sendPacket(...)”方法会找到packet 数据发送到客户端。“sendPacket(...)”主要源码如下：

|  |
| --- |
| private int sendPacket(ByteBuffer pkt, int maxChunks, OutputStream out,  boolean transferTo, DataTransferThrottler throttler) throws IOException {  ... ...  *//sockOut 对象为客户端socket对象，这里从磁盘读取数据返回给客户端*fileIoProvider.transferToSocketFully(  ris.getVolumeRef().getVolume(), sockOut, fileCh, blockInPosition,  dataLen, waitTime, transferTime);  ... ...  } |

以上代码中“fileIoProvider.transferToSocketFully(...)”就是从磁盘读取数据通过socket返回到客户端。

回到BlockReaderRemote.newBlockReader(...)方法中，在该方法中最终通过“DataInputStream in = new DataInputStream(peer.getInputStream());”代码接受DataNode返回数据的流对象。

继续回到DFSInputStream.readWithStrategy(...)方法中，其源码如下：

|  |
| --- |
| protected synchronized int readWithStrategy(ReaderStrategy strategy)  throws IOException {  ... ...  *// 如果当前位置小于文件长度*if (pos < getFileLength()) {  if (pos > blockEnd || currentNode == null) {  *// 根据LocateBlocks列表生成BlockReader对象，在BlockReader中实现连接DataNode节点并准备接受数据的流对象。* *// 返回的currentNode 为block所在期望的DataNode*currentNode = blockSeekTo(pos); }  ... ...  *//从socket流中读取数据，使用到blockSeekTo 方法中从DataNode 获取数据的 in 流对象*int result = readBuffer(strategy, realLen, corruptedBlocks);  ... ...  *//返回读取的结果*return result;  } |

最终通过readBuffer(...)从DataNode中获取文件数据。
