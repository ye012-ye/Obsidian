Netty源码分析第一节课

课前概念

```plain
Netty目前：

同步的IO模型，异步的编程模型，典型的Reactor Pattern 的 高效的 IO 框架

同步IO模型：非阻塞的多路复用器

异步编程模型：promise+inEventLoop()

Reactor Pattern：

高效：FastThreadLocal，pools

框架：pipeline+handler
```

带着样一个概述去做源码分析，找到感觉：

```java
package com.bjmashibing.system.ai.nettysrc;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.string.StringEncoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;
import io.netty.util.AttributeKey;

public class NettySrc {

    public static void main(String[] args) throws InterruptedException, ClassNotFoundException {

//        NioSocketChannel client = new NioSocketChannel();
//        ChannelFuture writeFuture = client.write("");
//        writeFuture.get();
//        client.write("",client.newPromise());
//        client.flush();

        /*

         */
        ServerBootstrap boot = new ServerBootstrap();
        /*
        1,脚手架意识
        2，最主要的是server@socket、channel、bind的处理，【关注doBind方法】
        3，对serverSocket的注册
        4，暴露了register的能力
         */

        NioEventLoopGroup boss = new NioEventLoopGroup(1);//在服務端只做listen socket的註冊，boot.group

        NioEventLoopGroup worker = new NioEventLoopGroup();  //存放的是連接的socket，boot.childGroup
        /*

        EventExecutorGroup
        ——> EventExecutor[] children  ——> NioEventLoop
        EventLoopGroup

        NioEventLoop----SingleThread----EventLoop----EventExecutor
        netty中最核心的就是這個nioEventLoop
        run--> for(;;)--> 1,selector，2，runtasks

        1，selector優化
        2，cpu 100%

        Group:
        Loop:
        Executor:

         */

        ChannelFuture server = boot
                .group(boss, worker)
                /*
                io和线程的关系
                主从，混杂，单线程
                 */

                .channel(NioServerSocketChannel.class)
                .option(ChannelOption.SO_BACKLOG, 100)  //listensocket@recv-queue 放內核完成三次握手的連接backlog+1，serverSocket.accept(),其實是從recv-queue中獲取
                .handler(new LoggingHandler(LogLevel.ERROR))
//                .handler(new ChannelInitializer<NioServerSocketChannel>() {
//                    @Override
//                    protected void initChannel(NioServerSocketChannel ch) throws Exception {
//
//                    }
//                })
                .attr(AttributeKey.valueOf("msb"),"bbb")
                /*
                NioServerSocketChannel.class
                ——AbstractNioMessageChannel----unsafe
                channel:
                eventloop
                parent
                unsafe-->accept-->pipeline.read
                pipeline--< need AcceptHandler{do register!}
                alloc---->內存管理

                newUnsafe();
                newChannelPipeline();

                 */

                .childOption(ChannelOption.SO_KEEPALIVE, true)
                .childAttr(AttributeKey.valueOf("GlobKey"),"msb@glob")
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    public void initChannel(SocketChannel ch) throws Exception {
                        ch.pipeline().addLast(new StringEncoder());
                        ch.pipeline().addLast(new ServerHandler());
                    }
                })
                /*
                NioSocketChannel.class

                 */

                .bind(8888);
                /*
                激活方法
                1,initAndRegister()
                1-a:serverSocketChannel
                1-b:init():完成serversocket.pipeline.add(BootstrapAcceptHandler)
                1-c:register

                2,dobind:
                2-*:需要異步bind，沒線程呢？？？
                2-1：channel.eventLoop().execute，通過這種方式，啟動了netty的bossgroup中的NioEventLoop中的線程，並
                執行起來了run方法。

                 */

                /*
                因為bind中的dobind執行，讓NioEventLoop跑起來了，反應堆運行
                接下來採取看 EV的run方法~~~~

                run@select
                procesSelectedkeys()
                k == READ | ACCEPT
                netty把serverSocket的accpet和clientsocket的read，統一抽象成了 read
                unsafe.read
                【unsafe.read.accpet】-->【client@pipeline.add(handlers),register(通過 task推送到work線程)】
                是在boss的縣城裡執行了next(),並執行register，然後觸發了inEventLoop判斷

                我在課上分析了 read/accpet

                NioSocketChannel client = new NioSocketChannel();
                ChannelFuture writeFuture = client.write("");

                 */

        server.sync().channel().closeFuture().sync();

    }
}

class ServerHandler extends ChannelInboundHandlerAdapter {
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        System.out.println("Server received: " + in.toString(io.netty.util.CharsetUtil.UTF_8));
        ctx.write(msg); // 返回给客户端
        ctx.flush();
        ctx.fireChannelReadComplete();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        super.channelReadComplete(ctx);
    }

    public void handleSpecificMessage(ChannelHandlerContext ctx, ByteBuf in) {
        // 在这里处理特定类型的消息
        System.out.println("Server received a specific message: " + in.toString(io.netty.util.CharsetUtil.UTF_8));
        // 执行一些操作，例如保存消息、调用其他服务等等
    }

}
```
