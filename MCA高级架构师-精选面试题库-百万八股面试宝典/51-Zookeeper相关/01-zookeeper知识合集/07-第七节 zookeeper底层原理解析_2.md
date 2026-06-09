# 第七节 Zookeeper底层原理解析\_2

# 1.Zookeeper源码导入

源码下载地址：<https://archive.apache.org/dist/zookeeper/zookeeper-3.5.7/>

![](../../assets/627948abb42d4891.png)

解压到非中文目录,导入idea，注意配置好maven

![](../../assets/9f7ef9d8c83f070a.png)

# 2. ZK的持久化

## 2.1 源码分析

ZooKeeper适合读多写少的场景，读操作几乎是内存级别的，这得益于ZooKeeper将数据保存在内存中。数据在内存中，就有一个问题，ZooKeeper重启了数据还会在吗？

当然在了，ZooKeeper将数据以事务日志形式持久化到文件中。每个更新请求，必须先将事务日志写到文件中，然后才把数据同步到内存数据库。

Leader 和 Follower 中的数据会在内存和磁盘中各保存一份。所以需要将内存中的数据 持久化到磁盘中。

![](../../assets/c1a0252b7f96bd13.png)

在 **org.apache.zookeeper.server** 包下,看看源码是如何存储数据的

```java
public class DataTree {
    private final ConcurrentHashMap<String, DataNode> nodes =
        new ConcurrentHashMap<String, DataNode>();
  
  
    private final WatchManager dataWatches = new WatchManager();
    private final WatchManager childWatches = new WatchManager();
   
```

DataNode 是Zookeeper存储节点数据的最小单位

```java
public class DataNode implements Record {
    byte data[];
    Long acl;
    public StatPersisted stat;
    private Set<String> children = null;
    .....
    }

```

在 **org.apache.zookeeper.server.persistence** 包下的相关类是持久化相关的代码。

- 事务操作日志

```java
public interface TxnLog {

      // 设置服务状态
    void setServerStats(ServerStats serverStats);
  
    // 滚动日志
    void rollLog() throws IOException;
  
      // 追加
    boolean append(TxnHeader hdr, Record r) throws IOException;

    // 读取数据
    TxnIterator read(long zxid) throws IOException;
  
    // 获取最后一个zxid
    long getLastLoggedZxid() throws IOException;
  
    // 删除日志
    boolean truncate(long zxid) throws IOException;
  
    // 获取DbId
    long getDbId() throws IOException;
  
    // 提交
    void commit() throws IOException;

    // 日志同步时间
    long getTxnLogSyncElapsedTime();
   
    // 关闭日志
    void close() throws IOException;
   
      // 读取日志接口
    public interface TxnIterator {
  
          // 获取头信息
        TxnHeader getHeader();
  
        // 获取传输内容
        Record getTxn();
   
        // 下一条记录
        boolean next() throws IOException;
  
        // 关闭资源
        void close() throws IOException;
  
        // 获取存储的大小
        long getStorageSize() throws IOException;
    }
}
```

- 快照

```java
public interface SnapShot {
  
         // 反序列化方法
    long deserialize(DataTree dt, Map<Long, Integer> sessions) 
        throws IOException;
  
        // 序列化方法
    void serialize(DataTree dt, Map<Long, Integer> sessions, 
            File name) 
        throws IOException;
  
        //查找最近的快照文件
    File findMostRecentSnapshot() throws IOException;
  
    //释放资源
    void close() throws IOException;
} 
```

## 2.2 事务日志

针对每一次客户端的事务操作，Zookeeper都会将他们记录到事务日志中，当然，Zookeeper也会将数据变更应用到内存数据库中。

### 2.2.1 事务日志存放目录

事务日志文件默认存储在dataDir目录下，因为每次事务请求都是一次磁盘IO操作，事务日志的写入性能直接影响了ZooKeeper对事务请求的吞吐，为了更高的吞吐和低延迟，建议单独为事务日志配置一个目录dataLogDir，以免受其他操作影响。

![](../../assets/b4ad84fa4d3e4ea7.png)

**dataLogDir**下会先生成一个子目录**version2**，2表示ZooKeeper日志格式的版本号，同一版本的日志可以互相迁移恢复数据。

version2下才是事务日志文件 。

![](../../assets/c1e5566aba1f4bfe.png)

### 2.2.2 文件大小和后缀名

事务日志的文件有两个特点：

- 文件大小出奇一致：都是67108880KB，即64MB。

- 文件名后缀是一串看似有些规律的数字，而且随着修改时间推移呈递增状态。

```plain
dataDir=/usr/local/zookeeper-cluster/zookeeper-1/data
```

![](../../assets/833d1c17497f54be.png)

**1）磁盘空间预分配**

- 文件大小都是64MB，是因为日志文件的磁盘空间预分配。

- 事务日志不断追加写入文件的操作会触发底层磁盘IO为文件开辟新的磁盘块，即磁盘Seek，为了避免频繁的文件大小增长带来的磁盘Seek开销，ZooKeeper在创建事务日志文件时就向操作系统预分配了一块比较大的磁盘块，保证了单一事务日志文件所占用的磁盘块是连续的，以此提升事务的写入性能。默认是64MB，空闲部分用空字符（\0）填充。

- 如果后续检测到文件空间不足4KB，将扩容再次预分配64MB，直到创建新的事务日志文件。

**2）ZXID作为后缀名**

- 文件名后面的一串数字是事务ID：ZXID，并且是写入事务日志文件的第一条事务ZXID。

### 2.2.3 事务日志可视化

- 事务日志文件中存放的是二进制格式的数据，不能用vim、cat等工具直接打开，需要用apache-zookeeper-3.7.1 提供的脚本bin/zkTxnLogToolkit.sh打开：

```shell
[root@localhost zookeeper-1]# cd /usr/local/zookeeper-cluster/zookeeper-1/bin/

[root@localhost bin]# ./zkTxnLogToolkit.sh /usr/local/zookeeper-cluster/zookeeper-1/data/version-2/log.100000001 
```

![](../../assets/2580c5478b841257.png)

一行就是一个事务记录，每行从左到右依次是操作时间、客户端session ID、CXID（客户端操作序列号）、ZXID、操作类型（做了什么），如果操作类型是 createSession，后面的30000就是session的超时时间。

## 2.3 数据快照

### 2.3.1 查看数据快照

数据快照用于记录Zookeeper服务器上某一时刻的全量数据，并将其写入到指定的磁盘文件中。

目的： 快速恢复内存中的数据

> 可配置参数snapCount，设置两次快照之间的事务操作个数，zk节点记录完事务日志时，会统计判断是否需要做数据快照2.3.1 查看快照数据

快照文件，可以用apache-zookeeper-3.7.1 提供的脚本bin/zkTxnLogToolkit.sh打开：

```plain
[root@localhost zookeeper-1]# cd /usr/local/zookeeper-cluster/zookeeper-1/bin/

[root@localhost bin]# ./zkSnapShotToolkit.sh /usr/local/zookeeper-cluster/zookeeper-1/data/version-2/snapshot.0
```

快照事务日志文件名为： snapshot.<当时最大事务ID>，日志满了即进行下一次事务日志文件的创建

```shell
ZNode Details (count=5):
----
/
  cZxid = 0x00000000000000
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x00000000000000
  mtime = Thu Jan 01 08:00:00 CST 1970
  pZxid = 0x00000000000000
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  dataLength = 0
----
/zookeeper
  cZxid = 0x00000000000000
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x00000000000000
  mtime = Thu Jan 01 08:00:00 CST 1970
  pZxid = 0x00000000000000
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  dataLength = 0
----
/zookeeper/config
  cZxid = 0x00000000000000
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x00000000000000
  mtime = Sun Dec 04 02:49:59 CST 2022
  pZxid = 0x00000000000000
  cversion = 0
  dataVersion = -1
  aclVersion = -1
  ephemeralOwner = 0x00000000000000
  dataLength = 147
----
/zookeeper/quota
  cZxid = 0x00000000000000
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x00000000000000
  mtime = Thu Jan 01 08:00:00 CST 1970
  pZxid = 0x00000000000000
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  dataLength = 0
```

### 2.3.2 数据快照的作用

1. **数据持久化：** ZooKeeper数据快照是ZooKeeper数据的持久化存储方式之一。通过数据快照，ZooKeeper可以在服务关闭或崩溃后重新启动时将数据加载回内存中，从而保持数据的持久性。

2. **数据备份和恢复：** 数据快照允许将ZooKeeper的数据定期备份到磁盘上。在需要恢复数据的情况下，可以使用最近的数据快照进行恢复，以减少数据损失。

3. **高可用性：** 数据快照是ZooKeeper实现高可用性的基础之一。通过持久化存储数据，即使ZooKeeper服务节点崩溃，新的节点也可以通过加载最近的数据快照来恢复数据状态，从而实现服务的快速恢复。

要注意，数据快照只是ZooKeeper数据持久化的一部分。除了数据快照，ZooKeeper还使用事务日志（transaction log）来记录每个写操作的细节，以确保数据的一致性和可恢复性。

# 3.ZK服务端初始化源码解析

![](../../assets/53accc298fe12156.png)

## 3.1.1 zk服务端启动脚本分析

1）Zookeeper服务端的启动命令是zkServer.sh start

zkServer.sh

![](../../assets/3ba2eda1ba8679c6.png)

```shell
#!/usr/bin/env bash

ZOOBIN="${BASH_SOURCE-$0}"
ZOOBIN="$(dirname "${ZOOBIN}")"
ZOOBINDIR="$(cd "${ZOOBIN}"; pwd)"

if [ -e "$ZOOBIN/../libexec/zkEnv.sh" ]; then
  . "$ZOOBINDIR"/../libexec/zkEnv.sh # 相当于获取zkEnv.sh中的环境变量（ZOOCFG=“zoo.cfg”）
else
  . "$ZOOBINDIR"/zkEnv.sh
fi

```

![](../../assets/e06ebc808f126be3.png)

```shell
if [ "x$JMXDISABLE" = "x" ] || [ "$JMXDISABLE" = 'false' ]
then
  echo "ZooKeeper JMX enabled by default" >&2
  if [ "x$JMXPORT" = "x" ]
  then
    # for some reason these two options are necessary on jdk6 on Ubuntu
    #   accord to the docs they are not necessary, but otw jconsole cannot
    #   do a local attach
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=$JMXLOCALONLY org.apache.zookeeper.server.quorum.QuorumPeerMain"
  else
    if [ "x$JMXAUTH" = "x" ]
    then
      JMXAUTH=false
    fi
    if [ "x$JMXSSL" = "x" ]
    then
      JMXSSL=false
    fi
    if [ "x$JMXLOG4J" = "x" ]
    then
      JMXLOG4J=true
    fi
    echo "ZooKeeper remote JMX Port set to $JMXPORT" >&2
    echo "ZooKeeper remote JMX authenticate set to $JMXAUTH" >&2
    echo "ZooKeeper remote JMX ssl set to $JMXSSL" >&2
    echo "ZooKeeper remote JMX log4j set to $JMXLOG4J" >&2
    ZOOMAIN="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMXPORT -Dcom.sun.management.jmxremote.authenticate=$JMXAUTH -Dcom.sun.management.jmxremote.ssl=$JMXSSL -Dzookeeper.jmx.log4j.disable=$JMXLOG4J org.apache.zookeeper.server.quorum.QuorumPeerMain"
  fi
else
    echo "JMX disabled by user request" >&2
    ZOOMAIN="org.apache.zookeeper.server.quorum.QuorumPeerMain"
fi
```

## 3.1.2 zk服务端启动入口

![](../../assets/5a18589d35dc622e.png)

1. 查找 QuorumPeerMain

```java
public static void main(String[] args) {
  QuorumPeerMain main = new QuorumPeerMain();
  try {
    //初始化节点并运行，args相当于提交参数中的 zoo.cfg
    main.initializeAndRun(args);
  } catch (IllegalArgumentException e) {
    //......
  } 
  LOG.info("Exiting normally");
  System.exit(0);
}
```

2. initializeAndRun

```java
    //args [zoo.fig]
        protected void initializeAndRun(String[] args)
        throws ConfigException, IOException, AdminServerException
    {
          // 管理zk的配置信息
        QuorumPeerConfig config = new QuorumPeerConfig();
        if (args.length == 1) {
              //1 解析参数，zoo.cfg和myid 
            config.parse(args[0]);
        }

        // Start and schedule the the purge task
          //启动定时任务， 对过期的快照，执行删除（默认该功能关闭）
        DatadirCleanupManager purgeMgr = new DatadirCleanupManager(config
                .getDataDir(), config.getDataLogDir(), config
                .getSnapRetainCount(), config.getPurgeInterval());
        purgeMgr.start();

        if (args.length == 1 && config.isDistributed()) {
              //启动集群
            runFromConfig(config);
        } else {
            LOG.warn("Either no config or no quorum defined in config, running "
                    + " in standalone mode");
            // there is only server in the quorum -- run as standalone
            ZooKeeperServerMain.main(args);
        }
    }
```

## 3.1.3 解析参数zoo.cfg和myid

![](../../assets/c5974038975368d7.png)

- **QuorumPeerConfig.java**

```java
   public void parse(String path) throws ConfigException {
        LOG.info("Reading configuration from: " + path);
   
        try {
              // 校验文件路径是否存在
            File configFile = (new VerifyingFileFactory.Builder(LOG)
                .warnForRelativePath()
                .failForNonExistingPath()
                .build()).create(path);
    
            Properties cfg = new Properties();
            FileInputStream in = new FileInputStream(configFile);
            try {
                  //加载配置文件
                cfg.load(in);
                configFileStr = path;
            } finally {
                in.close();
            }
            //解析配置文件
            parseProperties(cfg);
        } catch (IOException e) {
            throw new ConfigException("Error processing " + path, e);
        } catch (IllegalArgumentException e) {
            throw new ConfigException("Error processing " + path, e);
        }   
  
        。。。。。。
    }
```

- **QuorumPeerConfig.java**

```java
    public void parseProperties(Properties zkProp)
    throws IOException, ConfigException {
        int clientPort = 0;
        int secureClientPort = 0;
        String clientPortAddress = null;
        String secureClientPortAddress = null;
        VerifyingFileFactory vff = new VerifyingFileFactory.Builder(LOG).warnForRelativePath().build();
  
          // 读取zoo.cfg文件中的属性值，并赋值给 QuorumPeerConfig
        for (Entry<Object, Object> entry : zkProp.entrySet()) {
            String key = entry.getKey().toString().trim();
            String value = entry.getValue().toString().trim();
            if (key.equals("dataDir")) {
                dataDir = vff.create(value);
            } else if (key.equals("dataLogDir")) {
                dataLogDir = vff.create(value);
            } else if (key.equals("clientPort")) {
                clientPort = Integer.parseInt(value);
            } else if (key.equals("localSessionsEnabled")) {
            。。。。。。
        }
  
  
        if (dynamicConfigFileStr == null) {
            setupQuorumPeerConfig(zkProp, true);
            if (isDistributed() && isReconfigEnabled()) {
                // we don't backup static config for standalone mode.
                // we also don't backup if reconfig feature is disabled.
                backupOldConfig();
            }
        }
    }
```

- **QuorumPeerConfig.java**

```java
    void setupQuorumPeerConfig(Properties prop, boolean configBackwardCompatibilityMode)
            throws IOException, ConfigException {
        quorumVerifier = parseDynamicConfig(prop, electionAlg, true, configBackwardCompatibilityMode);
        setupMyId();
        setupClientPort();
        setupPeerType();
        checkValidity();
    }
```

- **QuorumPeerConfig.java**

```java
    private void setupMyId() throws IOException {
        File myIdFile = new File(dataDir, "myid");
        // standalone server doesn't need myid file.
        if (!myIdFile.isFile()) {
            return;
        }
        BufferedReader br = new BufferedReader(new FileReader(myIdFile));
        String myIdString;
        try {
            myIdString = br.readLine();
        } finally {
            br.close();
        }
        try {
              //将解析的myid文件中的ID复赋值给serverID
            serverId = Long.parseLong(myIdString);
            MDC.put("myid", myIdString);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("serverid " + myIdString
                    + " is not a number");
        }
    }
```

## 3.1.4 过期快照删除

![](../../assets/41e6ef648d733bb1.png)

可以启动定时任务，对过期的快照，执行删除。默认该功能时关闭的

```java
    protected void initializeAndRun(String[] args)
        throws ConfigException, IOException, AdminServerException
    {
        QuorumPeerConfig config = new QuorumPeerConfig();
        if (args.length == 1) {
              // 解析参数，zoo.cfg 和 myid
            config.parse(args[0]);
        }

        // Start and schedule the the purge task
          //启动定时任务，对过期快照，执行删除 （默认关闭）
        DatadirCleanupManager purgeMgr = new DatadirCleanupManager(
          config.getDataDir(), 
          config.getDataLogDir(), 
          //最少保留快照个数。 默认是3
          config.getSnapRetainCount(), 
          //默认0 表示关闭
          config.getPurgeInterval()
        );
  
          //启动清除快照线程
        purgeMgr.start();

        if (args.length == 1 && config.isDistributed()) {
              //启动集群
            runFromConfig(config);
        } else {
            LOG.warn("Either no config or no quorum defined in config, running "
                    + " in standalone mode");
            // there is only server in the quorum -- run as standalone
            ZooKeeperServerMain.main(args);
        }
    }

        protected int snapRetainCount = 3;
    protected int purgeInterval = 0;
```

- **DatadirCleanupManager**

```java
    public void start() {
        if (PurgeTaskStatus.STARTED == purgeTaskStatus) {
            LOG.warn("Purge task is already running.");
            return;
        }
        // Don't schedule the purge task with zero or negative purge interval.
        // 默认purgeInterval=0，该任务关闭直接返回
        if (purgeInterval <= 0) {
            LOG.info("Purge task is not scheduled.");
            return;
        }

          // 否则创建一个定时任务
        timer = new Timer("PurgeTask", true);
        // 清理快照任务
        TimerTask task = new PurgeTask(dataLogDir, snapDir, snapRetainCount);
  
        // 如果purgeInterval设置的值是1，表示1小时检查一次，判断是否有过期快照，有就删除
        timer.scheduleAtFixedRate(task, 0, TimeUnit.HOURS.toMillis(purgeInterval));

        purgeTaskStatus = PurgeTaskStatus.STARTED;
    }
```

```java
    static class PurgeTask extends TimerTask {
        private File logsDir;
        private File snapsDir;
        private int snapRetainCount;

        public PurgeTask(File dataDir, File snapDir, int count) {
            logsDir = dataDir;
            snapsDir = snapDir;
            snapRetainCount = count;
        }

        @Override
        public void run() {
            LOG.info("Purge task started.");
            try {
                  //清理过期数据
                PurgeTxnLog.purge(logsDir, snapsDir, snapRetainCount);
            } catch (Exception e) {
                LOG.error("Error occurred while purging.", e);
            }
            LOG.info("Purge task completed.");
        }
    }
```

- PurgeTxnLog

```java
/**
 * 从指定的数据目录和快照目录中清除过时的快照文件。
 * 如果保留的快照文件数量少于3个，则抛出IllegalArgumentException异常。
 *
 * @param dataDir 数据目录，存储Zookeeper事务日志文件
 * @param snapDir 快照目录，存储Zookeeper快照文件
 * @param num 保留的最近快照文件数量
 * @throws IOException 当清除过程中发生I/O错误时抛出
 */  
public static void purge(File dataDir, File snapDir, int num) throws IOException {
        if (num < 3) {
            throw new IllegalArgumentException(COUNT_ERR_MSG);
        }

        // 创建FileTxnSnapLog对象，用于管理事务日志和快照文件
        FileTxnSnapLog txnLog = new FileTxnSnapLog(dataDir, snapDir);

          // 获取最近的num个快照文件
        List<File> snaps = txnLog.findNRecentSnapshots(num);
        int numSnaps = snaps.size();
        if (numSnaps > 0) {
              ///删除较旧的快照文件，保留最近的num个快照文件
            purgeOlderSnapshots(txnLog, snaps.get(numSnaps - 1));
        }
    }
```

## 3.1.5 初始化通信组件

![](../../assets/dabd795a65ab9e7a.png)

```java
/**
 * 初始化并运行Zookeeper服务器。
 *
 * @param args 命令行参数数组
 * @throws ConfigException 配置异常，当配置文件解析错误或缺少必要配置项时抛出
 * @throws IOException I/O异常，当处理文件或网络数据时发生错误时抛出
 * @throws AdminServerException 管理服务器异常，当管理服务器出现问题时抛出
 */
protected void initializeAndRun(String[] args)
    throws ConfigException, IOException, AdminServerException
{
    // 创建QuorumPeerConfig对象，用于解析和保存配置
    QuorumPeerConfig config = new QuorumPeerConfig();

    // 如果只有一个参数，则将其作为配置文件进行解析
    if (args.length == 1) {
        config.parse(args[0]);
    }

    // 启动和调度清理任务DatadirCleanupManager，用于定期清理过时的快照和事务日志文件
    DatadirCleanupManager purgeMgr = new DatadirCleanupManager(config.getDataDir(), config.getDataLogDir(),
            config.getSnapRetainCount(), config.getPurgeInterval());
    purgeMgr.start();

    // 如果只有一个参数，并且配置指定为分布式模式，则运行作为分布式模式的Zookeeper服务器
    if (args.length == 1 && config.isDistributed()) {
        runFromConfig(config);
    } else {
        // 如果没有配置文件或者配置文件中没有定义Quorum，则以单机模式运行Zookeeper服务器
        LOG.warn("未找到配置文件或配置中未定义Quorum，将以独立模式运行");
        // 在单机模式下只有一个服务器，直接运行ZookeeperServerMain
        ZooKeeperServerMain.main(args);
    }
}
```

- runFromConfig

```java
/**
 * 根据给定的配置启动QuorumPeer（Zookeeper服务器的一种模式）。
 *
 * @param config QuorumPeerConfig对象，包含配置信息
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 * @throws AdminServerException 管理服务器异常，当管理服务器出现问题时抛出
 */
public void runFromConfig(QuorumPeerConfig config) throws IOException, AdminServerException {
    try {
        // 注册log4j的JMX控制，用于监控日志
        ManagedUtil.registerLog4jMBeans();
    } catch (JMException e) {
        LOG.warn("无法注册log4j的JMX控制", e);
    }

    LOG.info("正在启动Quorum Peer");

    try {
        ServerCnxnFactory cnxnFactory = null;
        ServerCnxnFactory secureCnxnFactory = null;

        // 如果配置中定义了客户端端口地址，则创建并配置ServerCnxnFactory
        if (config.getClientPortAddress() != null) {
            cnxnFactory = ServerCnxnFactory.createFactory();
            cnxnFactory.configure(config.getClientPortAddress(), config.getMaxClientCnxns(), false);
        }

        // 如果配置中定义了安全客户端端口地址，则创建并配置ServerCnxnFactory
        if (config.getSecureClientPortAddress() != null) {
            secureCnxnFactory = ServerCnxnFactory.createFactory();
  
            secureCnxnFactory.configure(config.getSecureClientPortAddress(), config.getMaxClientCnxns(), true);
        }

        // 获取QuorumPeer实例
        quorumPeer = getQuorumPeer();

        // 配置QuorumPeer的事务日志和快照目录
        quorumPeer.setTxnFactory(new FileTxnSnapLog(config.getDataLogDir(), config.getDataDir()));

        // 设置是否允许本地会话和会话升级
        quorumPeer.enableLocalSessions(config.areLocalSessionsEnabled());
        quorumPeer.enableLocalSessionsUpgrading(config.isLocalSessionsUpgradingEnabled());

        // 设置选举算法、服务器ID、时钟周期等参数
        quorumPeer.setElectionType(config.getElectionAlg());
        quorumPeer.setMyid(config.getServerId());
        quorumPeer.setTickTime(config.getTickTime());
        quorumPeer.setMinSessionTimeout(config.getMinSessionTimeout());
        quorumPeer.setMaxSessionTimeout(config.getMaxSessionTimeout());
        quorumPeer.setInitLimit(config.getInitLimit());
        quorumPeer.setSyncLimit(config.getSyncLimit());
        quorumPeer.setConfigFileName(config.getConfigFilename());

        // 初始化ZKDatabase，用于保存Zookeeper的数据
        quorumPeer.setZKDatabase(new ZKDatabase(quorumPeer.getTxnFactory()));

        // 设置QuorumPeer的选举配置
        quorumPeer.setQuorumVerifier(config.getQuorumVerifier(), false);
        if (config.getLastSeenQuorumVerifier() != null) {
            quorumPeer.setLastSeenQuorumVerifier(config.getLastSeenQuorumVerifier(), false);
        }

        // 在ZKDatabase中初始化配置数据
        quorumPeer.initConfigInZKDatabase();

        // 设置ServerCnxnFactory和SecureCnxnFactory
        quorumPeer.setCnxnFactory(cnxnFactory);
        quorumPeer.setSecureCnxnFactory(secureCnxnFactory);

        // 设置是否使用SSL进行加密通信
        quorumPeer.setSslQuorum(config.isSslQuorum());

        // 设置是否启用端口统一，即使用单个端口处理客户端连接
        quorumPeer.setUsePortUnification(config.shouldUsePortUnification());

        // 设置Peer类型和是否启用同步
        quorumPeer.setLearnerType(config.getPeerType());
        quorumPeer.setSyncEnabled(config.getSyncEnabled());

        // 设置是否监听所有IP地址的连接请求
        quorumPeer.setQuorumListenOnAllIPs(config.getQuorumListenOnAllIPs());

        // 设置是否支持SSL证书文件的热加载
        if (config.sslQuorumReloadCertFiles) {
            quorumPeer.getX509Util().enableCertFileReloading();
        }

        // 设置是否启用Quorum的SASL认证
        quorumPeer.setQuorumSaslEnabled(config.quorumEnableSasl);
        if (quorumPeer.isQuorumSaslAuthEnabled()) {
            // 设置Quorum Peer的SASL认证配置
            quorumPeer.setQuorumServerSaslRequired(config.quorumServerRequireSasl);
            quorumPeer.setQuorumLearnerSaslRequired(config.quorumLearnerRequireSasl);
            quorumPeer.setQuorumServicePrincipal(config.quorumServicePrincipal);
            quorumPeer.setQuorumServerLoginContext(config.quorumServerLoginContext);
            quorumPeer.setQuorumLearnerLoginContext(config.quorumLearnerLoginContext);
        }

        // 设置Quorum Peer的连接线程池大小
        quorumPeer.setQuorumCnxnThreadsSize(config.quorumCnxnThreadsSize);

        // 初始化QuorumPeer
        quorumPeer.initialize();

        // 启动ZK --> QuorumPeer
        quorumPeer.start();

        // 等待QuorumPeer线程的结束
        quorumPeer.join();
    } catch (InterruptedException e) {
        // 警告，一般来说这是可以接受的
        LOG.warn("Quorum Peer被中断", e);
    }
} 
```

- ServerCnxnFactory配置地址不为空时，默认使用ZooKeeper自带的基于NIO的连接工厂。![](../../assets/338a91b276804e19.png)

```java
/**
 * 创建ZooKeeper服务器连接工厂的实例，用于处理客户端与服务器之间的连接。
 *
 * @return ServerCnxnFactory的实例，用于处理连接
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
static public ServerCnxnFactory createFactory() throws IOException {
  
    // 获取系统属性中配置的服务器连接工厂名称
    String serverCnxnFactoryName = System.getProperty(ZOOKEEPER_SERVER_CNXN_FACTORY);

    // 如果未指定工厂名称，则默认使用 NIOServerCnxnFactory
    if (serverCnxnFactoryName == null) {
        serverCnxnFactoryName = NIOServerCnxnFactory.class.getName();
    }

    try {
        // 根据工厂名称使用反射创建ServerCnxnFactory的实例
        ServerCnxnFactory serverCnxnFactory = (ServerCnxnFactory) Class.forName(serverCnxnFactoryName)
                .getDeclaredConstructor().newInstance();

        // 记录使用的服务器连接工厂名称
        LOG.info("正在使用 {} 作为服务器连接工厂", serverCnxnFactoryName);

        // 返回创建的ServerCnxnFactory实例
        return serverCnxnFactory;
    } catch (Exception e) {
        // 如果创建失败，将异常封装为IOException并抛出
        IOException ioe = new IOException("无法实例化 " + serverCnxnFactoryName);
        ioe.initCause(e);
        throw ioe;
    }
}
```

- Ctrl + 左键 ，进入configure（）![](../../assets/89660489211b9dc8.png)

- 进入到的是接口， 找到NIO实现类![](../../assets/90a4e32ce693a426.png)

- NIOServerCnxnFactory中的configure()

- 参数说明

- `config.getClientPortAddress()`: 这个参数是一个InetSocketAddress对象，表示ZooKeeper服务器监听的客户端连接地址。ZooKeeper服务器将在该地址上接受客户端连接。

- `config.getMaxClientCnxns()`: 这个参数表示ZooKeeper服务器允许的最大客户端连接数。在达到这个限制后，服务器将不再接受新的客户端连接。

- `false`: 这个参数表示是否启用安全连接。在上述代码中，设置为 `false`，表示不启用安全连接，即普通的非安全连接。

```java
/**
 * 配置NIO服务器连接处理器。
 *
 * @param addr    服务器监听的InetSocketAddress
 * @param maxcc   最大客户端连接数
 * @param secure  是否启用安全连接（不支持）
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
@Override
public void configure(InetSocketAddress addr, int maxcc, boolean secure) throws IOException {
    // 检查是否启用了安全连接，如果是，则抛出不支持异常（NIOServerCnxn不支持SSL）
    if (secure) {
        throw new UnsupportedOperationException("NIOServerCnxn不支持SSL连接");
    }

    // 配置SASL登录，用于认证和授权客户端
    configureSaslLogin();

    // 设置最大客户端连接数
    maxClientCnxns = maxcc;

    // 设置会话过期时间，默认为10秒
    sessionlessCnxnTimeout = Integer.getInteger(ZOOKEEPER_NIO_SESSIONLESS_CNXN_TIMEOUT, 10000);

    // 创建连接过期队列，使用会话过期时间作为过期间隔
    cnxnExpiryQueue = new ExpiryQueue<NIOServerCnxn>(sessionlessCnxnTimeout);

    // 创建连接过期线程，用于处理过期连接
    expirerThread = new ConnectionExpirerThread();

    // 获取可用处理器的数量，用于选择合适的线程数
    int numCores = Runtime.getRuntime().availableProcessors();

    // 计算选择器线程的数量，根据可用处理器数来决定，最少为1
    numSelectorThreads = Integer.getInteger(ZOOKEEPER_NIO_NUM_SELECTOR_THREADS,
            Math.max((int) Math.sqrt((float) numCores / 2), 1));
    if (numSelectorThreads < 1) {
        throw new IOException("numSelectorThreads必须至少为1");
    }

    // 计算工作线程的数量，默认为可用处理器数的两倍
    numWorkerThreads = Integer.getInteger(ZOOKEEPER_NIO_NUM_WORKER_THREADS, 2 * numCores);

    // 工作线程的关闭超时时间，默认为5000毫秒
    workerShutdownTimeoutMS = Long.getLong(ZOOKEEPER_NIO_SHUTDOWN_TIMEOUT, 5000);

    // 打印配置信息
    LOG.info("正在配置NIO连接处理器，会话超时时间为 " + (sessionlessCnxnTimeout / 1000) + " 秒，"
            + numSelectorThreads + " 个选择器线程，"
            + (numWorkerThreads > 0 ? numWorkerThreads : "没有") + " 个工作线程，以及 "
            + (directBufferBytes == 0 ? "gathered writes." : ("" + (directBufferBytes / 1024) + " kB direct buffers.")));

    // 创建并初始化选择器线程
    for (int i = 0; i < numSelectorThreads; ++i) {
        selectorThreads.add(new SelectorThread(i));
    }

    // 打开服务器套接字通道，并进行基本配置，绑定2181端口，可以接受客户端请求
    this.ss = ServerSocketChannel.open();
    ss.socket().setReuseAddress(true);
    LOG.info("正在绑定到端口 " + addr);
  
      //绑定2181端口
    ss.socket().bind(addr);
    ss.configureBlocking(false);

    // 创建并启动接受线程，用于接受客户端连接
    acceptThread = new AcceptThread(ss, addr, selectorThreads);
}
```

# 4.zk服务端加载数据源码解析

![](../../assets/02099b31b4b66a17.png)

1. **zk 中的数据模型，是一棵树，DataTree，每个节点，叫做 DataNode。**

2. **zk 集群中的 DataTree 时刻保持状态同步。**

3. **Zookeeper 集群中每个 zk 节点中，数据在内存和磁盘中都有一份完整的数据。**

- **内存数据:DataTree。**

- **磁盘数据:快照文件 + 编辑日志。**

**加载数据流程**

![](../../assets/b75c03a485d26512.png)

## 4.1 启动数据恢复-快照数据

![](../../assets/0575b5d75b13b938.png)

**1）启动集群**

```plain
    public void runFromConfig(QuorumPeerConfig config)
            throws IOException, AdminServerException
    {
      try {
          ManagedUtil.registerLog4jMBeans();
      } catch (JMException e) {
          LOG.warn("Unable to register log4j JMX control", e);
      }

      LOG.info("Starting quorum peer");
      try {
  ......
          // 启动集群
          quorumPeer.start();
          quorumPeer.join();
      } catch (InterruptedException e) {
          // warn, but generally this is ok
          LOG.warn("Quorum Peer interrupted", e);
      }
    }
```

**2）冷启动恢复数据**

- **QuorumPeer.java**

- **主要包含四个方面**

- **loadDataBase() 涉及到的核心类是ZKDatabase，并借助于FileTxnSnapLog工具类将快照snap和事务日志 transaction log，反序列化到内存中，最终构建出内存数据结构DataTree.**

- **startServerCnxnFactory(): 本身也可以作为一个线程**

- **startLeaderElection()：这个主要是初始化一些Leader选举工作**

- **super.start(): QuorumPeer本身也是一个线程，继承了Thread类，这里就是启动QuorumPeer线程，执行QuorumPeer.run方法**

```plain
@Override
public synchronized void start() {
  if (!getView().containsKey(myid)) {
    throw new RuntimeException("My id " + myid + " not in the peer list");
  }
  // 冷启动数据恢复，加载磁盘文件到内存，服务器启动阶段需要进行数据恢复
  loadDataBase();
  
  startServerCnxnFactory();
  try {
    // 启动通信工厂实例对象
    adminServer.start();
  } catch (AdminServerException e) {
    LOG.warn("Problem starting AdminServer", e);
    System.out.println(e);
  }
  // 准备选举环境
  startLeaderElection();
  // 执行选举
  super.start();
}
```

- **loadDataBase**

```plain
private void loadDataBase() {
    try {
        // 点击进入 加载磁盘数据到内存
        zkDb.loadDataBase();
```

```plain
/**
 * 加载ZooKeeper服务器的数据和元数据信息。
 */
private void loadDataBase() {
    try {
        // 加载磁盘数据到内存
        zkDb.loadDataBase();

        // 加载epoch信息
        // 获取ZooKeeper服务器上已处理的最后一个事务的zxid
        long lastProcessedZxid = zkDb.getDataTree().lastProcessedZxid;
      
        // 从最后处理的zxid中获取epoch
        long epochOfZxid = ZxidUtils.getEpochFromZxid(lastProcessedZxid);

        // 读取当前的epoch信息，该信息保存在磁盘的文件中
        try {
            currentEpoch = readLongFromFile(CURRENT_EPOCH_FILENAME);
        } catch(FileNotFoundException e) {
            // 如果文件不存在，使用最后处理的zxid所属的epoch作为合理的默认值
            // 这种情况通常只会在升级ZooKeeper代码版本时发生一次
            currentEpoch = epochOfZxid;
            LOG.info(CURRENT_EPOCH_FILENAME + " 文件未找到！创建一个合理的默认值 {}。这通常只会在升级ZooKeeper时发生一次。",
                    currentEpoch);
            // 将当前的epoch信息写入文件中
            writeLongToFile(CURRENT_EPOCH_FILENAME, currentEpoch);
        }

        // 检查当前的epoch是否比最后处理的zxid所属的epoch要小
        if (epochOfZxid > currentEpoch) {
            throw new IOException("当前的epoch " + ZxidUtils.zxidToString(currentEpoch) + " 比最后处理的zxid " + lastProcessedZxid + " 所属的epoch要旧。");
        }

        // 读取已接受的epoch信息，该信息也保存在磁盘的文件中
        try {
            acceptedEpoch = readLongFromFile(ACCEPTED_EPOCH_FILENAME);
        } catch(FileNotFoundException e) {
            // 如果文件不存在，使用最后处理的zxid所属的epoch作为合理的默认值
            // 这种情况通常只会在升级ZooKeeper代码版本时发生一次
            acceptedEpoch = epochOfZxid;
            LOG.info(ACCEPTED_EPOCH_FILENAME + " 文件未找到！创建一个合理的默认值 {}。这通常只会在升级ZooKeeper时发生一次。",
                    acceptedEpoch);
            // 将已接受的epoch信息写入文件中
            writeLongToFile(ACCEPTED_EPOCH_FILENAME, acceptedEpoch);
        }

        // 检查已接受的epoch是否比当前的epoch要小
        if (acceptedEpoch < currentEpoch) {
            throw new IOException("已接受的epoch " + ZxidUtils.zxidToString(acceptedEpoch) + " 小于当前的epoch " + ZxidUtils.zxidToString(currentEpoch));
        }
    } catch(IOException ie) {
        // 发生错误时记录日志并抛出运行时异常
        LOG.error("无法从磁盘加载数据库", ie);
        throw new RuntimeException("无法启动Quorum服务器", ie);
    }
}
```

- **loadDataBase**

```plain
/**
 * 从快照和事务日志中恢复ZooKeeper服务器的数据库和会话信息。
 * 
 * @return 恢复的最后一个事务zxid
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public long loadDataBase() throws IOException {
    // 调用snapLog的restore方法，从快照和事务日志中恢复数据和会话信息
    // 返回恢复的最后一个事务zxid
    long zxid = snapLog.restore(dataTree, sessionsWithTimeouts, commitProposalPlaybackListener);

    // 标记数据库已经初始化完成
    initialized = true;

    // 返回恢复的最后一个事务zxid
    return zxid;
}
```

- **FileTxnSnapLog.java ---> restore()**

![](../../assets/cf3d6c7cdb43f28b.png)

进入到 **snapLog.deserialize**

![](../../assets/28e14218e2695936.png)

- **详细注释**

```plain
/**
 * 从快照和事务日志中恢复数据树和会话信息，并返回最后一个事务zxid。
 * 如果快照日志未找到，将根据情况进行初始化空数据库。
 *
 * @param dt 数据树（DataTree）对象，用于恢复快照中的数据
 * @param sessions 存储会话信息的Map对象，用于恢复事务日志中的会话信息
 * @param listener 播放监听器（PlayBackListener），用于处理事务日志的回放操作
 * @return 恢复的最后一个事务zxid
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public long restore(DataTree dt, Map<Long, Integer> sessions, PlayBackListener listener) throws IOException {
    // 从快照日志中反序列化数据树和会话信息，deserializeResult为反序列化结果，即恢复的最后一个事务zxid
    long deserializeResult = snapLog.deserialize(dt, sessions);

    // 创建事务日志对象，用于处理数据树和会话信息的事务日志
    FileTxnLog txnLog = new FileTxnLog(dataDir);

    // 创建一个恢复最终器（RestoreFinalizer）接口的实现，并实现其中的run()方法
    RestoreFinalizer finalizer = () -> {
        // 快速从事务日志中回放数据并恢复会话信息
        long highestZxid = fastForwardFromEdits(dt, sessions, listener);
        return highestZxid;
    };

    // 如果快照日志未找到，根据情况进行初始化空数据库
    if (-1L == deserializeResult) {
        /* 如果找不到快照日志，意味着需要初始化一个空的数据库（参考ZOOKEEPER-2325） */
        if (txnLog.getLastLoggedZxid() != -1) {
            // ZOOKEEPER-3056: 为旧版本的ZooKeeper（3.4.x，3.5.3之前的版本）提供逃生通道
            if (!trustEmptySnapshot) {
                // 如果不信任空快照，则抛出异常
                throw new IOException(EMPTY_SNAPSHOT_WARNING + " 数据错误!");
            } else {
                // 否则，记录警告日志，并执行恢复最终器的run()方法
                LOG.warn("{}，这只应该在升级过程中允许。", EMPTY_SNAPSHOT_WARNING);
                return finalizer.run();
            }
        }
        /* TODO: (br33d) 我们应该在restore()上放一个ConcurrentHashMap，或者在save()上使用Map */
        // 保存当前的数据树和会话信息到快照，此处需要考虑并发问题，此TODO可以后续优化
        save(dt, (ConcurrentHashMap<Long, Integer>)sessions);
        /* 返回zxid为0，表示数据库是空的 */
        return 0;
    }

    // 返回恢复的最后一个事务zxid，即快照和事务日志中的最后一个zxid
    return finalizer.run();
}
```

**快照数据序列化**

![](../../assets/085b987cee411e2e.png)

**进入到**FileSnap.java --> **deserialize(dt, sessions, ia)** 方法。

![](../../assets/83a50530f9de9ebe.png)

- **详细注释**

```plain
/**
 * 从快照文件中反序列化数据树（DataTree）和会话信息，并根据校验和验证快照文件的完整性。
 * 该方法会尝试读取最多100个快照文件，如果在这些快照中找不到有效的快照，则返回-1表示快照未找到。
 *
 * @param dt 数据树（DataTree）对象，用于反序列化快照中的数据
 * @param sessions 存储会话信息的Map对象，用于反序列化快照中的会话信息
 * @return 反序列化后数据树（DataTree）的最后一个事务zxid
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public long deserialize(DataTree dt, Map<Long, Integer> sessions) throws IOException {
    // 查找最多100个有效快照文件，并将它们保存在snapList中
    List<File> snapList = findNValidSnapshots(100);

    // 如果找不到有效快照文件，则返回-1表示快照未找到
    if (snapList.size() == 0) {
        return -1L;
    }

    File snap = null;
    boolean foundValid = false;

    // 遍历快照列表，尝试从每个快照文件中读取数据
    for (int i = 0, snapListSize = snapList.size(); i < snapListSize; i++) {
        snap = snapList.get(i);
        LOG.info("正在读取快照文件：" + snap);

        try (InputStream snapIS = new BufferedInputStream(new FileInputStream(snap));
             CheckedInputStream crcIn = new CheckedInputStream(snapIS, new Adler32())) {
            // 使用BinaryInputArchive创建InputArchive对象，并从快照文件中反序列化数据到数据树和会话信息中
            InputArchive ia = BinaryInputArchive.getArchive(crcIn);
          
         
            deserialize(dt, sessions, ia);

            // 获取快照文件的校验和和读取的校验和，用于验证快照文件的完整性
            long checkSum = crcIn.getChecksum().getValue();
            long val = ia.readLong("val");

            // 验证快照文件的校验和是否与读取的校验和一致
            if (val != checkSum) {
                throw new IOException("快照文件CRC校验错误：" + snap);
            }

            // 标记找到了有效的快照文件，并跳出循环
            foundValid = true;
            break;
        } catch (IOException e) {
            // 如果读取快照文件时发生错误，记录警告日志，并尝试读取下一个快照文件
            LOG.warn("读取快照文件出现问题：" + snap, e);
        }
    }

    // 如果找不到有效的快照文件，则抛出异常表示快照未找到
    if (!foundValid) {
        throw new IOException("未能在 " + snapDir + " 中找到有效的快照文件");
    }

    // 设置数据树的最后一个已处理事务zxid为当前快照文件的zxid，并返回该zxid
    dt.lastProcessedZxid = Util.getZxidFromName(snap.getName(), SNAPSHOT_FILE_PREFIX);
    return dt.lastProcessedZxid;
}
```

**FileSnap.java** --> **deserialize(dt, sessions, ia)** 方法。

**进入到**SerializeUtils.deserializeSnapshot(dt, ia, sessions);

![](../../assets/82e412dc316bed76.png)

- **详细注释**

```plain
/**
 * 从InputArchive中反序列化数据树（DataTree）和会话信息，并验证快照文件的魔数。
 *
 * @param dt 数据树（DataTree）对象，用于反序列化快照中的数据
 * @param sessions 存储会话信息的Map对象，用于反序列化快照中的会话信息
 * @param ia InputArchive对象，用于读取快照文件的序列化数据
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public void deserialize(DataTree dt, Map<Long, Integer> sessions, InputArchive ia) throws IOException {
    // 创建FileHeader对象并从InputArchive中反序列化文件头部信息
    FileHeader header = new FileHeader();
    header.deserialize(ia, "fileheader");

    // 验证快照文件的魔数是否匹配，如果魔数不匹配则抛出IOException异常
    if (header.getMagic() != SNAP_MAGIC) {
        throw new IOException("魔数不匹配，快照文件头部魔数为 " + header.getMagic()
                + " !=  " + FileSnap.SNAP_MAGIC);
    }

    // 使用SerializeUtils.deserializeSnapshot方法反序列化数据树和会话信息
    SerializeUtils.deserializeSnapshot(dt, ia, sessions);
}
```

向下继续追踪，进入 dt.deserialize(ia, "tree");方法

![](../../assets/c01f0104c5396381.png)

- **详细代码**

```plain
/**
 * 从InputArchive中反序列化快照中的数据树（DataTree）和会话信息。
 *
 * @param dt 数据树（DataTree）对象，用于反序列化快照中的数据
 * @param ia InputArchive对象，用于读取快照文件的序列化数据
 * @param sessions 存储会话信息的Map对象，用于反序列化快照中的会话信息
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public static void deserializeSnapshot(DataTree dt, InputArchive ia, Map<Long, Integer> sessions) throws IOException {
    // 读取快照中会话信息的数量
    int count = ia.readInt("count");

    // 循环处理快照中的会话信息
    while (count > 0) {
        // 从InputArchive中读取会话ID和超时时间，并存储到sessions Map中
        long id = ia.readLong("id");
        int to = ia.readInt("timeout");
        sessions.put(id, to);

        // 如果日志级别是Trace，记录会话信息的加载过程
        if (LOG.isTraceEnabled()) {
            ZooTrace.logTraceMessage(LOG, ZooTrace.SESSION_TRACE_MASK,
                    "加载快照中的会话信息 --- 会话ID: " + id
                    + " 超时时间: " + to);
        }

        // 继续处理下一个会话信息
        count--;
    }

    // 使用DataTree对象的deserialize方法反序列化快照中的数据树
    dt.deserialize(ia, "tree");
}
```

**进入到DataTree ---> dt.deserialize(ia, "tree");**

![](../../assets/985e0bcb002a21c3.png)

- 详细注释 将快照内容加载到内存。

```java
/**
 * 从InputArchive中反序列化数据树（DataTree）和节点信息，并更新ACL缓存、路径Trie和统计节点。
 *
 * @param ia InputArchive对象，用于读取快照文件的序列化数据
 * @param tag 标记字符串，用于区分不同的数据
 * @throws IOException 当处理文件或网络数据时发生错误时抛出
 */
public void deserialize(InputArchive ia, String tag) throws IOException {
    // 从InputArchive中反序列化ACL缓存信息
    aclCache.deserialize(ia);

    // 清空数据树的节点信息和路径Trie
    nodes.clear();
    pTrie.clear();

    // 从InputArchive中读取路径信息，并依次反序列化数据树的节点信息
    String path = ia.readString("path");
    while (!"/".equals(path)) {
        // 创建DataNode对象，并从InputArchive中读取节点信息反序列化到DataNode中
        DataNode node = new DataNode();
        ia.readRecord(node, "node");

        // 将反序列化后的节点信息放入节点映射表nodes中，路径为key
        nodes.put(path, node);

        // 在加入节点缓存之前对节点进行同步，以防止并发修改
        synchronized (node) {
            // 将节点的ACL信息添加到ACL缓存中，以便后续使用
            aclCache.addUsage(node.acl);
        }

        // 处理节点的路径信息，更新路径Trie和统计节点信息
        int lastSlash = path.lastIndexOf('/');
        if (lastSlash == -1) {
            // 如果节点路径为根节点"/"，则设置root节点为当前节点
            root = node;
        } else {
            // 否则，获取父节点的路径，并将当前节点加入父节点的子节点列表
            String parentPath = path.substring(0, lastSlash);
            DataNode parent = nodes.get(parentPath);
            if (parent == null) {
                // 如果找不到父节点，则抛出异常表示数据树不正确
                throw new IOException("无效的数据树，无法找到路径 " + parentPath + " 的父节点：" + path);
            }
            parent.addChild(path.substring(lastSlash + 1));

            // 根据节点的临时所有者（ephemeralOwner）类型，将节点添加到对应的列表中
            long eowner = node.stat.getEphemeralOwner();
            EphemeralType ephemeralType = EphemeralType.get(eowner);
            if (ephemeralType == EphemeralType.CONTAINER) {
                containers.add(path);
            } else if (ephemeralType == EphemeralType.TTL) {
                ttls.add(path);
            } else if (eowner != 0) {
                HashSet<String> list = ephemerals.get(eowner);
                if (list == null) {
                    list = new HashSet<String>();
                    ephemerals.put(eowner, list);
                }
                list.add(path);
            }
        }

        // 继续读取下一个节点的路径信息
        path = ia.readString("path");
    }

    // 将根节点"/"加入节点映射表nodes中
    nodes.put("/", root);

    // 反序列化数据树完成后，更新节点的配额信息、创建路径Trie和更新统计节点
    setupQuota();

    // 清除未使用的ACL缓存项，减少内存占用
    aclCache.purgeUnused();
}
```

## 4.2 启动数据恢复 - 事务日志

**再次回到 FileTxnSnapLog.java ----> restore**

进入到FileTxnSnapLog.java 的fastForwardFromEdits方法

![](../../assets/179b8be777b76b3f.png)

进入到FileTxnSnapLog.java 的processTransaction方法

![](../../assets/29ff14cd3d05b72d.png)

**详细注释**

```plain
/**
 * 处理事务日志中的事务数据，根据不同事务类型执行相应操作。
 *
 * @param hdr 事务头部信息
 * @param dt 数据树（DataTree）对象，用于应用事务数据
 * @param sessions 存储会话信息的Map对象，用于处理与会话相关的事务操作
 * @param txn 事务记录（Transaction Record），包含事务操作的具体内容
 * @throws KeeperException.NoNodeException 如果事务操作涉及到节点不存在的情况，则抛出此异常
 */
public void processTransaction(TxnHeader hdr, DataTree dt,
                               Map<Long, Integer> sessions, Record txn)
        throws KeeperException.NoNodeException {
    ProcessTxnResult rc;
    // 根据事务类型进行不同的处理
    switch (hdr.getType()) {
        case OpCode.createSession:
            // 处理创建会话（createSession）事务
            // 将新会话信息放入sessions map中
            sessions.put(hdr.getClientId(),
                    ((CreateSessionTxn) txn).getTimeOut());
            if (LOG.isTraceEnabled()) {
                // 记录创建会话操作的日志
                ZooTrace.logTraceMessage(LOG, ZooTrace.SESSION_TRACE_MASK,
                        "playLog --- create session in log: 0x"
                                + Long.toHexString(hdr.getClientId())
                                + " with timeout: "
                                + ((CreateSessionTxn) txn).getTimeOut());
            }
            // 让数据树（DataTree）有机会同步其lastProcessedZxid
            // 处理事务数据并返回结果
            rc = dt.processTxn(hdr, txn);
            break;
        case OpCode.closeSession:
            // 处理关闭会话（closeSession）事务
            // 从sessions map中移除对应的会话信息
            sessions.remove(hdr.getClientId());
            if (LOG.isTraceEnabled()) {
                // 记录关闭会话操作的日志
                ZooTrace.logTraceMessage(LOG, ZooTrace.SESSION_TRACE_MASK,
                        "playLog --- close session in log: 0x"
                                + Long.toHexString(hdr.getClientId()));
            }
            // 处理事务数据并返回结果
            rc = dt.processTxn(hdr, txn);
            break;
        default:
            // 默认情况下，直接处理事务数据并返回结果
            rc = dt.processTxn(hdr, txn);
    }

    /**
     * Snapshots are lazily created. So when a snapshot is in progress,
     * there is a chance for later transactions to make into the
     * snapshot. Then when the snapshot is restored, NONODE/NODEEXISTS
     * errors could occur. It should be safe to ignore these.
     */
    // 如果处理事务出现错误（rc.err不为Code.OK），则打印调试日志，忽略错误
    if (rc.err != Code.OK.intValue()) {
        LOG.debug(
                "Ignoring processTxn failure hdr: {}, error: {}, path: {}",
                hdr.getType(), rc.err, rc.path);
    }
}
```

进入到 dt.processTxn(hdr, txn);

![](../../assets/a0e011ea0ea56102.png)

- 详细注释

```java
/**
 * 处理单个事务（Transaction），根据事务类型执行相应的操作。
 * 
 * @param header 事务头部信息，包含客户端ID、连接ID、事务zxid和事务类型等信息
 * @param txn 事务记录（Transaction Record），包含事务操作的具体内容
 * @param isSubTxn 表示是否为子事务，用于处理多事务（multi）的情况
 * @return 返回一个ProcessTxnResult对象，包含处理结果的相关信息
 */
public ProcessTxnResult processTxn(TxnHeader header, Record txn, boolean isSubTxn) {
    ProcessTxnResult rc = new ProcessTxnResult();
    // 初始化ProcessTxnResult对象的相关属性
    rc.clientId = header.getClientId();
    rc.cxid = header.getCxid();
    rc.zxid = header.getZxid();
    rc.type = header.getType();
    rc.err = 0;
    rc.multiResult = null;
    try {
        switch (header.getType()) {
            // 处理create类型的事务（创建节点）
            case OpCode.create:
                // 将txn强制转换为CreateTxn对象
                CreateTxn createTxn = (CreateTxn) txn;
                rc.path = createTxn.getPath();
                // 调用createNode方法创建节点
                createNode(
                        createTxn.getPath(),
                        createTxn.getData(),
                        createTxn.getAcl(),
                        createTxn.getEphemeral() ? header.getClientId() : 0,
                        createTxn.getParentCVersion(),
                        header.getZxid(), header.getTime(), null);
                break;
            // 处理create2类型的事务（创建节点，带返回节点状态信息）
            case OpCode.create2:
                // 将txn强制转换为CreateTxn对象
                CreateTxn create2Txn = (CreateTxn) txn;
                rc.path = create2Txn.getPath();
                Stat stat = new Stat();
                // 调用createNode方法创建节点，并将创建结果的状态信息保存在rc.stat中
                createNode(
                        create2Txn.getPath(),
                        create2Txn.getData(),
                        create2Txn.getAcl(),
                        create2Txn.getEphemeral() ? header.getClientId() : 0,
                        create2Txn.getParentCVersion(),
                        header.getZxid(), header.getTime(), stat);
                rc.stat = stat;
                break;
            // 处理createTTL类型的事务（创建带过期时间的节点）
            case OpCode.createTTL:
                // 将txn强制转换为CreateTTLTxn对象
                CreateTTLTxn createTtlTxn = (CreateTTLTxn) txn;
                rc.path = createTtlTxn.getPath();
                stat = new Stat();
                // 调用createNode方法创建带过期时间的节点，并将创建结果的状态信息保存在rc.stat中
                createNode(
                        createTtlTxn.getPath(),
                        createTtlTxn.getData(),
                        createTtlTxn.getAcl(),
                        EphemeralType.TTL.toEphemeralOwner(createTtlTxn.getTtl()),
                        createTtlTxn.getParentCVersion(),
                        header.getZxid(), header.getTime(), stat);
                rc.stat = stat;
                break;
            // 处理createContainer类型的事务（创建容器节点）
            case OpCode.createContainer:
                // 将txn强制转换为CreateContainerTxn对象
                CreateContainerTxn createContainerTxn = (CreateContainerTxn) txn;
                rc.path = createContainerTxn.getPath();
                stat = new Stat();
                // 调用createNode方法创建容器节点，并将创建结果的状态信息保存在rc.stat中
                createNode(
                        createContainerTxn.getPath(),
                        createContainerTxn.getData(),
                        createContainerTxn.getAcl(),
                        EphemeralType.CONTAINER_EPHEMERAL_OWNER,
                        createContainerTxn.getParentCVersion(),
                        header.getZxid(), header.getTime(), stat);
                rc.stat = stat;
                break;
            // 处理delete类型的事务（删除节点）
            case OpCode.delete:
            case OpCode.deleteContainer:
                // 将txn强制转换为DeleteTxn对象
                DeleteTxn deleteTxn = (DeleteTxn) txn;
                rc.path = deleteTxn.getPath();
                // 调用deleteNode方法删除节点
                deleteNode(deleteTxn.getPath(), header.getZxid());
                break;
            // 处理reconfig和setData类型的事务（修改节点数据）
            case OpCode.reconfig:
            case OpCode.setData:
                // 将txn强制转换为SetDataTxn对象
                SetDataTxn setDataTxn = (SetDataTxn) txn;
                rc.path = setDataTxn.getPath();
                // 调用setData方法设置节点数据，并将修改结果的状态信息保存在rc.stat中
                rc.stat = setData(setDataTxn.getPath(), setDataTxn.getData(), setDataTxn.getVersion(),
                        header.getZxid(), header.getTime());
                break;
            // 处理setACL类型的事务（设置节点ACL）
            case OpCode.setACL:
                // 将txn强制转换为SetACLTxn对象
                SetACLTxn setACLTxn = (SetACLTxn) txn;
                rc.path = setACLTxn.getPath();
                // 调用setACL方法设置节点ACL，并将设置结果的状态信息保存在rc.stat中
                rc.stat = setACL(setACLTxn.getPath(), setACLTxn.getAcl(), setACLTxn.getVersion());
                break;
            // 处理closeSession类型的事务（关闭会话）
            case OpCode.closeSession:
                // 调用killSession方法关闭对应的会话
                killSession(header.getClientId(), header.getZxid());
                break;
            // 处理error类型的事务（错误类型）
            case OpCode.error:
                // 将txn强制转换为ErrorTxn对象
                ErrorTxn errTxn = (ErrorTxn) txn;
                // 设置ProcessTxnResult的err字段为错误码
                rc.err = errTxn.getErr();
                break;
            // 处理check类型的事务（检查版本号）
            case OpCode.check:
                // 将txn强制转换为CheckVersionTxn对象
                CheckVersionTxn checkTxn = (CheckVersionTxn) txn;
                rc.path = checkTxn.getPath();
                break;
            // 处理multi类型的事务（多事务）
            case OpCode.multi:
                // 将txn强制转换为MultiTxn对象
                MultiTxn multiTxn = (MultiTxn) txn;
                List<Txn> txns = multiTxn.getTx
```

# 5. ZK选举源码分析

![](../../assets/8691084e1edbc06e.png)

1. **QuorumPeer类**是ZK的核心组件，负责管理整个ZooKeeper集群的运行和协调工作。每个ZooKeeper节点（服务器）都是一个 `QuorumPeer`实例。

2. **FastLeaderElection类** 进行领导者选举的类，包含了选举领导者的算法。

3. **QuorumCnxManager类** 是处理QuorumPeer之间网络连接的管理器。用于支持集群节点之间的数据同步和领导者选举。

4. **WorkerReceiver**：选票接收器，该线程会不断的从QuorumCnxManager.RecvQueue队列中取出其它服务器发送过来的数据，并转换成一个Notification通知对象，然后转存到FastLeaderElection.recvqueue队列中。

5. **WorkerSender**：选票发送器，该线程主要负责将FastLeaderElection.sendqueue中的数据取出，放到QuorumCnxManager.queueSendMap中当前节点对应的发送队列中。

6. `recvQueue`是 `QuorumCnxManager`的一个成员变量，用于接收从QuorumPeer节点发送过来的数据。`recvQueue`是一个阻塞队列，用于在接收线程和处理线程之间传递消息。

7. **sendqueue：选票发送队列**

8. **recvqueue：选票接收队列**

## 5.1 ZK选举准备阶段

- **QuorumPeer.java**

![](../../assets/b1efedefbb2f74ab.png)

**进入startLeaderElection，可以看到创建选票操作**

![](../../assets/d619a3cc77306847.png)

**然后进入到createElectionAlgorithm，可以看到创建了，集群间网络连接的管理器 QuorumCnxManager**

![](../../assets/6984ff4e3664e495.png)

**进入到createCnxnManager() 方法**

![](../../assets/06647a485c268b3a.png)

**进入到QuorumCnxManager，初始化好了相关队列**

![](../../assets/cad15625997cddb7.png)

**回到QuorumPeer中的createElectionAlgorithm方法，继续往下看**

![](../../assets/0c8b494b8ab0a66f.png)

接下来找到Listener中，它是一个线程 找到它的run方法

![](../../assets/ea67e5316e213569.png)

![](../../assets/02163d4a84a2ea42.png)

再次回到QuorumPeer中的createElectionAlgorithm方法，继续往下看

![](../../assets/05f511a364a36241.png)

进入到 FastLeaderElection的构造

![](../../assets/d290f25c5b03a6f2.png)

进入starter方法

![](../../assets/e80323786bc3a81b.png)

## 5.2 选举执行阶段

前面的准备工作已经完成

![](../../assets/9e3000e312752606.png)

**执行 super.start(); 就相当于执行 QuorumPeer.java 类中的 run()方法，当 Zookeeper 启动后，首先都是 Looking 状态，通过选举，让其中一台服务器成为 Leader，其他的服务器成为 Follower。**

**找到run() 方法**

![](../../assets/5de7525e05458e4e.png)

![](../../assets/308da7b7d8a1c053.png)

**进入到核心方法：lookForLeader**

![](../../assets/faea90f2c649187b.png)

**生成一张选票，并发送选票**

![](../../assets/2f385e8a913353b6.png)

**进入到sendNotifications() 中，广播选票，把自己的选票发给其他服务器**

![](../../assets/74de7fb47219063e.png)

**ctrl+F 查找 WorkerSender**

![](../../assets/ea5ce857190c3af6.png)

**进入到 process()**

![](../../assets/2455bce57d0dc58f.png)

**进入到 toSend，如果是发给自己**

![](../../assets/f16c905434ace63b.png)

![](../../assets/1ad57e7e6e2b7c58.png)

**回到toSend 如果是else 就是往其他节点上发送**

![](../../assets/01028f797f4e008f.png)

![](../../assets/4294f41206cf53f0.png)

**接下来进入到 connectOne方法**

![](../../assets/25b598d3747b7153.png)

进入if判断中的 connectOne()

![](../../assets/53c1f0b63859ecc1.png)

进入到connectOne方法之后，可以看到一个同步方法

![](../../assets/74e27e26517b53fb.png)

![](../../assets/27b9f1b2311914d0.png)

接着进入到， startConnection方法， 创建并启动发送器线程和接收器线程

![](../../assets/a6bf46b12086f3bc.png)

接着往下看代码。

![](../../assets/dfc49c01be220ff0.png)

点击 SendWorker，并查找该类下的 run 方法，找到 send(b)

![](../../assets/8b5dbb5340adb690.png)

点击 RecvWorker，并查找该类下的 run 方法

![](../../assets/ff6413afb369682f.png)

进入到addToRecvQueue

![](../../assets/10d8167fc1c1d872.png)

![](../../assets/e7f5eb1deb36023e.png)

至此选举流程形成一个闭环
