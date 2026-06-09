心跳是干嘛的呢，说白了就是Nacos客户端注册到Nacos服务上之后，默认每隔5s要发送一次心跳请求（HTTP）。如果NacosServer15s没收到心跳，将服务的健康设置为false，30s没收到心跳，直接从注册表中剔除。

本质其实就是利用JUC包下的ScheduledThreadPoolExecutor去实现的定时任务，每隔5s，利用Java默认提供的方式发起的HTTP请求。

BeatInfo：封装当前心跳要携带的一些信息，没啥说的。

BeatReactor：发送心跳的。

- 在他的有参构造中，会初始化发送请求用到的NamingHttpClientProxy，本质就是Java自带的HttpURLConnection
- 其次还会初始化一个ScheduledThreadPoolExecutor，在内部会提交BeatTask任务，内部其实就是发送心跳请求，以及在当前服务没有在Nacos中找到时，会重新注册上去。
- 任务执行完，会重新将任务投递到ScheduledThreadPoolExecutor中。

**Ps：如果后期要注册到NacosServer上的服务成百上千，甚至上万个，每隔5s的一次请求，对于Nacos的压力也是比较大的，所以到了2.x有一个优化……上长连接~~**
