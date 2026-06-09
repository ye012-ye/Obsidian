# 1、生产者网络设计

## 架构设计图

![](../../assets/e7733aa9002c08b7.jpg)

# 2、生产者消息缓存机制

### 1、RecordAccumulator

将消息缓存到RecordAccumulator收集器中, 最后判断是否要发送。这个加入消息收集器，首先得从 Deque 里找到自己的目标分区，如果没有就新建一个批量消息 Deque 加进入

![](../../assets/a87b804499a708c6.png)

![](../../assets/bb54a5bf3867d5f7.png)

![](../../assets/78709fb3adbbee35.png)

![](../../assets/a6903bf4e63f66f1.png)

### 2、消息发送时机

如果达到发送阈值（**批次发送的条件为:缓冲区数据大小达到 batch.size 或者 linger.ms 达到上限，哪个先达到就算哪个**），唤醒Sender线程，

![](../../assets/39cab959e62bd263.png)

NetWorkClient 将 batch record 转换成 request client 的发送消息体, 并将待发送的数据按 【Broker Id <=> List】的数据进行归类

![](../../assets/aa8b92df0a5e9517.png)

![](../../assets/80283636f8c741dd.png)

![](../../assets/93e8855fbacaaf95.png)

![](../../assets/bc80f107b0485d0c.png)

与服务端不同的 Broker 建立网络连接，将对应 Broker 待发送的消息 List 发送出去。

![](../../assets/fb5a2f4fe84b364b.png)

9)、

![](../../assets/dfd8ae82fc934586.png)

![](../../assets/040e882869021213.png)

经过几轮跳转

![](../../assets/a1d43ce29bd2c3f1.png)

# 3、Kafka通讯组件解析

![](../../assets/e67d81099b0dd763.png)
