# **Consumer源码解读**

**本课程的核心技术点如下：**

1、consumer初始化  
2、如何选举Consumer Leader  
3、Consumer Leader是如何制定分区方案

4、Consumer如何拉取数据  
5、Consumer的自动偏移量提交

## Consumer初始化

![](../../assets/abdb00c18c5439fe.png)

从KafkaConsumer的构造方法出发，我们跟踪到核心实现方法

![](../../assets/7e8776710dfea78f.png)

这个方法的前面代码部分都是一些配置，我们分析源码要抓核心，我把核心代码给摘出来

### **NetworkClient**

**Consumer与Broker的核心通讯组件**

![](../../assets/9aa036d7547674d3.png)

### **ConsumerCoordinator**

**协调器，在Kafka消费中是组消费，协调器在具体进行消费之前要做很多的组织协调工作。**

![](../../assets/4a4be0a35d81ebaf.png)

### Fetcher

提取器，因为Kafka消费是拉数据的，所以这个Fetcher就是拉取数据的核心类

![](../../assets/d4009ec120dc6084.png)

而在这个核心类中，我们发现有很多很多的参数设置，这些就跟我们平时进行消费的时候配置有关系了，这里我们挑一些核心重点参数来讲一讲

#### fetch.min.bytes

每次fetch请求时，server应该返回的最小字节数。如果没有足够的数据返回，请求会等待，直到足够的数据才会返回。缺省为1个字节。多消费者下，可以设大这个值，以降低broker的工作负载。

#### fetch.max.bytes

每次fetch请求时，server应该返回的最大字节数。这个参数决定了可以成功消费到的最大数据。

比如这个参数设置的是50M，那么consumer能成功消费50M以下的数据，但是最终会卡在消费大于10M的数据上无限重试。fetch.max.bytes一定要设置到大于等于最大单条数据的大小才行。

默认是50M

![](../../assets/b5608f26cd88f2c4.png)

#### fetch.wait.max.ms

如果没有足够的数据能够满足fetch.min.bytes，则此项配置是指在应答fetch请求之前，server会阻塞的最大时间。缺省为500个毫秒。和上面的fetch.min.bytes结合起来，要么满足数据的大小，要么满足时间，就看哪个条件先满足。

这里说一下参数的默认值如何去找：

![](../../assets/90fa2abf9156e26d.png)

![](../../assets/1ff051c38af6b75f.png)

#### max.partition.fetch.bytes

指定了服务器从每个分区里返回给消费者的最大字节数，默认1MB。

假设一个主题有20个分区和5个消费者，那么每个消费者至少要有4MB的可用内存来接收记录，而且一旦有消费者崩溃，这个内存还需更大。注意，这个参数要比服务器的message.max.bytes更大，否则消费者可能无法读取消息。

*备注：1、Kafka入门笔记*

![](../../assets/cfba72db83e7d9c9.png)

#### max.poll.records

控制每次poll方法返回的最大记录数量。

默认是500

![](../../assets/662b314a725e3b2b.png)

## 如何选举Consumer Leader

回顾之前的内容

![](../../assets/2938d76d7c09c897.png)

那么如何完成以上的逻辑的，我们跟踪代码：

![](../../assets/27d40f3d530728a2.png)

### 1、消费者协调器与组协调器的通讯

![](../../assets/38e64ef81fdf2912.png)

![](../../assets/1a12b16940d53e57.png)

![](../../assets/84c8cddb54e361eb.png)

![](../../assets/416214493516b34c.png)

![](../../assets/91b1ac55eaa60ef4.png)

![](../../assets/e160312b4c89da1d.png)

![](../../assets/4c02909773959182.png)

![](../../assets/d89691bda0fce4bc.png)

对Broker的响应进行处理

![](../../assets/157d5c2b616e77e2.png)

![](../../assets/fb2dc98b52961310.png)

### 1、消费者协调器发起入组请求

![](../../assets/d3ce019591c79bf7.png)

![](../../assets/333a04a84632efbc.png)

![](../../assets/e1047020dbe49a43.png)

![](../../assets/156455a6db1f1f89.png)

![](../../assets/269e9f8fb3066840.png)

## Consumer Leader如何制定分区方案

回顾之前的内容

![](../../assets/16d1f4f8ec326647.png)

### 消费者分区策略

消费者参数

**partition.assignment.strategy**

分区分配给消费者的策略。默认为Range。允许自定义策略。

#### **Range**

把主题的连续分区分配给消费者。（如果分区数量无法被消费者整除、第一个消费者会分到更多分区）

#### **RoundRobin**

把主题的分区循环分配给消费者。

![](../../assets/4404a1046e00fd82.png)

#### StickyAssignor

初始分区和RoundRobin是一样

粘性分区：每一次分配变更相对上一次分配做最少的变动.

目标：

1、**分区的分配尽量的均衡**

2、**每一次重分配的结果尽量与上一次分配结果保持一致**

当这两个目标发生冲突时，优先保证第一个目标

比如有3个消费者（C0、C1、C2）、4个topic(T0、T1、T2、T34)，每个topic有2个分区（P1、P2）

![](../../assets/796d472ff214066f.png)

**C0:** **T0P0、T1P1、T3P0**

**C1: T0P1、T2P0、T3P1**

**C2: T1P0、T2P1**

如果C1下线 、如果按照RoundRobin

![](../../assets/7c975974d7624a38.png)

**C0:** **T0P0、T1P0、T2P0、T3P0**

**C2: T0P1、T1P1、T2P1、T3P1**

对比之前

![](../../assets/aa3a77171c12e787.png)

如果C1下线 、如果按照StickyAssignor

![](../../assets/a7957343435852f1.png)

**C0:** **T0P0、T1P1、T2P0、T3P0**

**C2: T0P1、T1P0、T2P1、T3P1**

对比之前

![](../../assets/aa3a77171c12e787.png)

![](../../assets/08bad1f5ff9f3765.png)

#### 自定义策略

extends 类AbstractPartitionAssignor，然后在消费者端增加参数：

properties.put(ConsumerConfig.PARTITION\_ASSIGNMENT\_STRATEGY\_CONFIG,类.class.getName());

即可。

### 消费者分区策略源码分析

接着上个章节的代码。

![](../../assets/ecb5c9ff7ee3cea9.png)

![](../../assets/771d612e08309dc2.png)

![](../../assets/aea02d158e268ef8.png)

![](../../assets/558094c84ec53a9c.png)

![](../../assets/fcb353bc0c43001f.png)

## Consumer拉取数据

这里就是拉取数据，核心Fetch类

![](../../assets/5ccf9ff716a450ad.png)

![](../../assets/a8a769d80c7521f8.png)

![](../../assets/c22bdeb8070d0b41.png)

## 自动提交偏移量

![](../../assets/4f82fdac17948ec8.png)

![](../../assets/030360c88952acd5.png)

![](../../assets/e3b6ad4760de9923.png)

![](../../assets/4251b0a3ba0c3d93.png)

![](../../assets/736d732a1a8fa059.png)

![](../../assets/d181fc287de84634.png)

![](../../assets/62fcc97383763308.png)

![](../../assets/1fb70e71f6c05932.png)

![](../../assets/9a315bd40dd46572.png)

当然，自动提交auto.commit.interval.ms

![](../../assets/0d89994e6ea88e4d.png)

默认5s

![](../../assets/501d3c5262dad7c6.png)

从源码上也可以看出

maybeAutoCommitOffsetsAsync 最后这个就是poll的时候会自动提交，而且没到auto.commit.interval.ms间隔时间也不会提交，如果没到下次自动提交的时间也不会提交。

这个autoCommitIntervalMs就是auto.commit.interval.ms设置的
