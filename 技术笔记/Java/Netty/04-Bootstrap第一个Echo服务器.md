---
title: Bootstrap：第一个 Echo 服务器
tags:
  - Java
  - Netty
  - Bootstrap
  - Echo
created: 2026-06-10
up: "[[00-MOC-Java-Netty从0基础到大神]]"
description: 使用 ServerBootstrap、Bootstrap 和 ChannelInitializer 写第一个 Netty Echo 服务端与客户端。
---

# Bootstrap：第一个 Echo 服务器

> [!tip] 本章目标
> 你要能跑起来第一个 Netty TCP 服务：客户端发什么，服务端回什么。

## Maven 依赖

```xml
<dependency>
    <groupId>io.netty</groupId>
    <artifactId>netty-all</artifactId>
    <version>4.2.15.Final</version>
</dependency>
```

> [!warning] 生产建议
> 学习用 `netty-all` 省事；生产项目更推荐用 `netty-bom` 管版本，再按需引入 `netty-buffer`、`netty-transport`、`netty-handler`、`netty-codec` 等模块。

## EchoServer

```java
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;

public class EchoServer {
    public static void main(String[] args) throws InterruptedException {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup();

        try {
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 128)
                    .childOption(ChannelOption.SO_KEEPALIVE, true)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            ch.pipeline().addLast(new EchoServerHandler());
                        }
                    });

            ChannelFuture future = bootstrap.bind(8080).sync();
            System.out.println("Echo server started on 8080");
            future.channel().closeFuture().sync();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}
```

## EchoServerHandler

```java
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;

public class EchoServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ctx.writeAndFlush(msg);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }
}
```

> [!warning] 这里为什么不 release
> `ctx.writeAndFlush(msg)` 把收到的消息继续写出去，所有权交给出站流程。后面学习 ByteBuf 时会单独讲引用计数和释放规则。

## 客户端骨架

```java
Bootstrap bootstrap = new Bootstrap();
bootstrap.group(new NioEventLoopGroup())
        .channel(NioSocketChannel.class)
        .handler(new ChannelInitializer<SocketChannel>() {
            @Override
            protected void initChannel(SocketChannel ch) {
                ch.pipeline().addLast(new EchoClientHandler());
            }
        });

ChannelFuture future = bootstrap.connect("127.0.0.1", 8080).sync();
```

## Bootstrap 常用配置

| 配置 | 含义 |
|---|---|
| `group` | 线程组 |
| `channel` | Channel 类型 |
| `option` | 服务端监听 Channel 配置 |
| `childOption` | 子连接 Channel 配置 |
| `handler` | 服务端监听 Channel 的 Handler |
| `childHandler` | 子连接 Pipeline 初始化 |

## 本章小结

> [!success] 跑起来以后再理解
> Netty 初学最怕盯着类图发呆。先把 Echo 跑起来，再顺着连接、读写、Handler、Pipeline 往下拆。

