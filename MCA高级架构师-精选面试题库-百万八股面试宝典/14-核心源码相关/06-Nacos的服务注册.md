服务注册：Nacos客户端将自己的各种元数据（服务名，IP，Port等等）封装好，基于grpc请求将自己的元数据注册到NacosServer中。

注册的大致流程。

- 在注册之前，Nacos客户端会将自己的各种信息封装成一个Instance实例，里面包含了服务名、IP、Port、权重、健康信息、是否开启、是否是临时节点等。
- 基于NacosNamingService，将封装好的Instace注册要NacosServer上。
- 咱们自己的服务一般都是临时服务，那就默认走的都是grpc的方式注册上去，利用NamingGrpcClientProxy实现的请求发送。

**Ps：咱们自己写的服务基本都是临时服务，一般类似MySQL之类的要注册Nacos才是持久化服务。**
