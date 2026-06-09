Yarn中资源主要包含Cpu和内存，Yarn集群在节点数固定的情况下如果性能有瓶颈，可以尝试进行如下参数的调节。这些参数可以配置在$HADOOP\_HOME/etc/hadoop/yarn-site.xml配置文件中。

1. **yarn.nodemanager.resource.detect-hardware-capabilities**

该参数表示是否让Yarn自动探测服务器的CPU和内存资源，默认值false。

2. **yarn.nodemanager.resource.cpu-vcores**

该参数可以指定每个NodeManager上可以使用的虚拟CPU核心数，一个物理CPU可以被划分成多个虚拟CPU，该参数配置值可以大于物理CPU个数，可以提高并发，但配置过大有可能会带来服务器处理不过来、负载增大问题。 默认值为-1/8，当yarn.nodemanager.resource.detect-hardware-capabilities为true时，在 Windows 和 Linux 系统中会自动确定使用的cpu核心数；否则默认值为8，手动配置时，建议该值比真CPU个数小几个，留出一定的CPU用于其他服务使用。

3. **yarn.nodemanager.resource.memory-mb**

该参数表示每个节点可以分配给NodeManager的内存量，单位MB。默认值为-1/8GB，当yarn.nodemanager.resource.detect-hardware-capabilities为true时，在 Windows 和 Linux 系统中会自动计算；否则默认值为8192MB（8GB）。手动配置时，建议给Yarn分配80%内存，留出20%给服务器其他服务使用。

4. **yarn.nodemanager.resource.percentage-physical-cpu-limit**

该参数指定NodeManager可以使用节点的物理CPU核心百分比，默认值100，表示Yarn NodeManager可以使用节点所有的物理CPU核心。建议可以设置为80%，留出20%给服务器其他服务使用。

5. **yarn.nodemanager.resource.system-reserved-memory-mb**

该参数表示NodeManager节点上为非Yarn进程保留的物理内存量。该配置仅在yarn.nodemanager.resource.detect-hardware-capabilities设置为true并且yarn.nodemanager.resource.memory-mb设置为-1时生效。默认值为-1，即20%\*（系统内存-HADOOP使用内存）

6. **yarn.nodemanager.resource.pcores-vcores-multiplier**

该参数表示将物理核心数转换成虚拟核心个数的乘数。默认值为1.0，表示一个物理的cpu当做一个vcore使用。提交到NodeManager上的任务有些是非计算型密集任务，有些是计算密集型任务，那么通过设置这个参数可以更合理的利用资源。一般如果集群资源够用，不需调节此参数。

7. **yarn.nodemanager.vmem-pmem-ratio**

该值表示Yarn中任务的单位物理内存可使用的虚拟内存比例，默认值为2.1，表示任务每分配1MB的物理内存，虚拟内存最大可使用2.1MB。如果Yarn集群中内存较为紧张可以适当调大该参数。一般集群内存够用，不需调节此参数。

虚拟内存是计算机系统内存管理的一种技术，为每个进程提供了连续的、私有的地址空间，让程序可以拥有超过物理内存大小的可用内存空间。在Yarn中，虚拟内存的原理是将容器的内存分配扩展到硬盘空间，使得每个容器都能认为自己拥有连续可用的内存，从而更有效地管理内存，减少出错，并提高系统资源利用率和整体性能。

8. **yarn.nodemanager.pmem-check-enabled**

是否启动一个线程检查container使用的物理内存量，如果使用内存量超出NodeManager分配使用的内存域值，则直接kill掉对应的任务，默认为true，不建议关闭。

9. **yarn.nodemanager.vmem-check-enabled**

是否启动一个线程检查container使用的虚拟内存量，如果使用内存量超出NodeManager分配使用的虚拟内存阈值，则直接kill掉对应的任务，默认为true。

10. **yarn.scheduler.minimum-allocation-mb**

该参数表示为每个Container容器请求分配的最小内存，默认值1024MB。如果容器请求的内存参数小于该值，会以1024MB进行分配，如果NodeManager可被分配的内存小于该值，则NodeManager会被ResourceManager关闭。

11. **yarn.scheduler.maximum-allocation-mb**

该参数表示为每个Container容器请求分配的最大内存，默认值8192 MB。如果容器请求的资源超过该值，程序抛出异常。

12. **yarn.scheduler.minimum-allocation-vcores**

该参数表示为每个Container容器请求分配的最小cpu个数，默认值为1，低于此值的请求将被设置为此属性对应的值。cpu 核数小于此值的NodeManager会被ResourceManager关闭。

13. **yarn.scheduler.maximum-allocation-vcores**

该参数表示为每个Container容器请求分配的最大cpu个数，默认值为4。如果容器请求的资源超过该值，程序抛出异常。
