# **Java虚拟线程**

## 一、虚拟线程介绍

> 在跟着玩虚拟线程之前，先确保掌握Java中的线程池ThreadPoolExecutor的基本使用，并且大概了解一些关于参数设置的重要性。
>
> 没掌握的，优先看下这个课程
>
> <https://www.mashibing.com/study?courseNo=2726&sectionNo=109322&systemId=1&courseVersionId=3632&versionsId=215>

---

> **虚拟线程（Virtual Thread）** ，是JDK 19版本推出的一个新特性，但是在其他的语言中，很早就有了。
>
> 如果你听到别人问你协程，纤程，轻量级线程、用户态线程、绿色线程等等，这种称呼在Java中都是在指虚拟线程。
>
> 注意，虚拟线程正式发布的版本其实是JDK21，在JDK19中，他可以称为预览版本，能看，默认不让用，但是可以用！

---

> 在玩虚拟线程之前，优先回顾一下普通线程的使用方式。
>
> 这种线程有一个特点：CPU去调度线程，线程去执行指令。
>
> 在程序中，设计到了多线程操作时，基本都是奔着提升程序性能去的，但是可能会涉及到一些问题。
>
> - 如果线程数量太多，CPU在调度多个线程时，存在上下文的切换操作，这种上下文切换会对CPU的性能带来一定的损耗。如果线程数太多，轻则性能变慢……
>
> - 每个线程都会占用一定的内存空间，如果业务需要构建的线程特别多，需要的内存资源也不小，甚至没限制线程个数的话，甚至可能出现OOM的问题。

```java
Thread t = new Thread(() -> {任务……});
t.start();
```

---

> 虽然一些同学在公司没有主动的涉及过去构建线程池处理业务之类的，但是在咱们的程序中，很多组件也会构建出对应的线程池的。
>
> - 启动一个Java程序，一般会部署到Web容器中，比如常见的Tomcat服务器，Tomcat服务器内部就有一个线程池，你每一个请求都要基于这个线程池里的线程去处理。
>
> - 比如使用SpringBoot的各种注解，也会涉及到线程池。 @Async，@Scheduled
>
> - 再比如Dubbo，RabbitMQ等等框架，他内部也会涉及到线程池。
>
> - 再追加上，自身业务可能主动的去使用的情况。
>
> - …………
>
> 你会发现，在Java程序中，为了提升程序的性能，多线程的操作是必不可少的。你主动用，你依赖的很多组件也会涉及到多线程的操作。。。
>
> So，咱们程序就必然可能会出现上述两种问题。

---

> 而Java中的虚拟线程就是为了解决上述这种两种问题的。
>
> - 大量的线程占用的内存资源会非常多，正常new Thread可能需要100kb~1M多， **而虚拟线程基本10kb不到。**
>
> - 线程数多，会导致CPU的性能损耗， **而虚拟线程不需要CPU直接调度，是JVM中的普通线程去调用虚拟线程。**
>
> Ps：有一点，虚拟线程可以解决IO密集的任务，因为IO密集的任务大多数的情况下，线程个数会比较多，CPU需要在线程直接做切换，而CPU密集的任务，本身就不存在太多的上下文切换操作。

## 二、基本API

> 首先，前面聊过，JDK21才算是正式发布的虚拟线程。
>
> 你需要准备好三个环境
>
> - IDEA的版本，低版本的IDEA无法支持JDK21。需要你换个新的。。。
>
> - 本地环境要准备JDK21。
>
> - 还需要给Maven配置上JDK21的编译插件。
>
> 构建一个简单的Maven工程~~

---

> Java中构建虚拟线程的方式，依赖是基于Thread去构建的。
>
> 而且构建出来的虚拟线程的引用也依然是Thread。。。
>
> 关于构建虚拟线程，这里优先记住ThreadFactory的方式，因为后期正常生产代码也需要。
>
> 不过前面的两种知道就可以。
>
> API不需要去背，后期会用到的，咋也忘不掉，不常用的，忘了也没事。

```java
package com.mashibing.virtual;

import java.io.IOException;
import java.util.concurrent.ThreadFactory;

public class Demo01 {

    public static void main(String[] args) throws IOException {
        // 1、创建虚拟线程并启动！
        // 虚拟线程你可以当做成守护线程，也就是说，在没有用户线程的情况下，虚拟线程无法支撑JVM的运行
        Thread t1 = Thread.ofVirtual().start(() -> {
            System.out.println("Hello Virtual Thread！");
        });

        // 2、创建线程，不启动
        Thread t2 = Thread.ofVirtual().unstarted(() -> {
            System.out.println(Thread.currentThread().getName() + "：虚拟线程，构建不启动，需要主动的start！");
        });
        t2.start();

  
        // 3、构建虚拟线程工厂，并指定常见信息
        ThreadFactory factory = Thread.ofVirtual()
                .name("vt-", 1)
                .uncaughtExceptionHandler((t, e) -> {
                    System.out.println(t.getName() + "：出现异常：" + e.getMessage());
                })
                .factory();
        Thread t3 = factory.newThread(() -> {
            int i = 1 / 0;
            System.out.println(Thread.currentThread().getName() + "：线程工厂构建的虚拟线程执行啦！");
        });
        t3.start();

        // 标准输入，避免JVM停止
        System.in.read();
    }
}

```

## 三、普通线程和虚拟线程的区别

### 3.1 内存资源占用

> 区别其实前面也聊得差不多了，这里更多的是查看效果！
>
> 准备两套代码，一套普通线程，一套虚拟线程，分别构建一万个线程对象，然后查看JVM程序对内存资源的占用情况。
>
> 通过下图，咱们可以看出
>
> - 普通线程在构建时，可以直接通过任务管理器看到线程个数的增长，其次内存资源也会有一个非常明显的上升，一个新的普通线程，大概55.7kb。
>
> - 虚拟线程在构建时，无法通过任务管理器直接看到线程个数的增长（但是变多了），其次内存资源的变化不大，一个虚拟线程大概1.5kb。
>
> 虚拟线程需要基于JVM内部自己管理的一个线程池去维护的。
>
> ![](../assets/f4590a6a294e8506.png)

### 3.2 性能的提升

> 提供了一套IO密集的任务，提供两个接口分别采用普通线程池以及虚拟线程去处理IO密集的任务
>
> 基于Jemeter压测得出结果
>
> 第一个测试结果，是普通线程没有合理的设置数值，导致任务处理慢，相比虚拟线程的性能差别特别大。
>
> 第二个测试结果，跟根据咱们当前测试的情况，调整了一个完美的数值。如此一看，相比虚拟线程的性能差别不大。
>
> 第三个测试结果，调整了IO任务的处理次数，这样依赖发现，普通线程处理的方式，性能又降低了。
>
> 得出一个好处，以后遇到IO密集的任务，你不需要考虑任何线程池参数的事了！
>
> ![](../assets/2bdeffa53a79861e.png)

## 四、虚拟线程的正确使用姿势

> 咱们前面玩的方式，都是构建ThreadFactory去构建虚拟线程。
>
> 但是之前咱们玩的方式基本都是基于线程池去execute提交任务。
>
> 虚拟线程也是提供了这种方式的。
>
> 可以基于借助Executors工具类里提供的一个API
>
> 只需要将咱们设置好的虚拟线程工厂扔进去，他返回的线程池就是虚拟线程池 **（虚拟线程不会复用）**

```java
public static ExecutorService newThreadPerTaskExecutor(ThreadFactory threadFactory) {
    return ThreadPerTaskExecutor.create(threadFactory);
}
```

```java
package com.example.demo.virtual;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Demo01 {

    public static void main(String[] args) throws IOException {
        ExecutorService executor = Executors.newThreadPerTaskExecutor(
                Thread.ofVirtual()
                        .name("vt-", 1)
                        .uncaughtExceptionHandler((t, e) -> {
                            System.out.println(t.getName() + "：出现异常：" + e.getMessage());
                        })
                        .factory());

        executor.execute(() -> {
            int i = 1/0;
            System.out.println(Thread.currentThread().getName() + "：线程工厂构建的虚拟线程执行啦！");
        });

        System.in.read();
    }
}

```
