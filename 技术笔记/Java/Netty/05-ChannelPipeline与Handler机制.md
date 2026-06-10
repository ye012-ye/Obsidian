---
title: ChannelPipeline 与 Handler 机制
tags:
  - Java
  - Netty
  - Pipeline
  - Handler
created: 2026-06-10
up: "[[00-MOC-Java-Netty从0基础到大神]]"
description: 理解入站、出站、ChannelHandlerContext 和 Pipeline 的流水线机制。
---

# ChannelPipeline 与 Handler 机制

> [!tip] 本章目标
> 你要能设计一条清晰的协议处理流水线，而不是把所有逻辑塞进一个 Handler。

## Pipeline 是流水线

```mermaid
graph LR
    A["Socket 字节"] --> B["FrameDecoder"]
    B --> C["MessageDecoder"]
    C --> D["AuthHandler"]
    D --> E["BusinessHandler"]
    E --> F["MessageEncoder"]
    F --> G["Socket 写出"]
```

## 入站和出站

| 方向 | 接口 | 典型事件 |
|---|---|---|
| 入站 Inbound | `ChannelInboundHandler` | 连接激活、读数据、异常 |
| 出站 Outbound | `ChannelOutboundHandler` | 写数据、flush、connect、bind |

入站通常从 pipeline 头往后走，出站通常从当前位置往前找出站 Handler。

> [!warning] 方向很重要
> 解码器通常是入站，编码器通常是出站。放错位置或调用错 `ctx.write` / `channel.write`，会让事件走向和你想的不一样。

## SimpleChannelInboundHandler

```java
public class StringMessageHandler extends SimpleChannelInboundHandler<String> {

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, String msg) {
        System.out.println("receive: " + msg);
        ctx.writeAndFlush("server received: " + msg);
    }
}
```

`SimpleChannelInboundHandler` 默认会在处理后释放入站消息，适合已经解码好的业务对象。

## ChannelHandlerContext

`ctx` 是 Handler 和 Pipeline 的上下文。

常用方法：

1. `ctx.fireChannelRead(msg)`：继续传递入站事件。
2. `ctx.writeAndFlush(msg)`：从当前上下文向前传播出站事件。
3. `ctx.channel()`：拿到当前连接。
4. `ctx.executor()`：拿到当前 EventLoop。
5. `ctx.close()`：关闭连接。

## Handler 是否可共享

如果 Handler 没有可变成员状态，可以加：

```java
@ChannelHandler.Sharable
public class LoggingHandler extends ChannelInboundHandlerAdapter {
}
```

> [!danger] 别乱共享有状态 Handler
> Handler 被多个 Channel 共享时，成员变量也会被多个连接共享。比如把当前用户 ID 放成员变量里，会直接串号。

## 推荐 Pipeline 模板

```java
ch.pipeline()
        .addLast("idle", new IdleStateHandler(60, 30, 0))
        .addLast("frameDecoder", new LengthFieldBasedFrameDecoder(1024 * 1024, 0, 4, 0, 4))
        .addLast("messageDecoder", new MessageDecoder())
        .addLast("messageEncoder", new MessageEncoder())
        .addLast("auth", new AuthHandler())
        .addLast("business", new BusinessHandler());
```

## 本章小结

> [!success] Pipeline 设计原则
> 一层只做一件事：拆包、解码、认证、业务、编码、异常。清晰的 Pipeline 比“万能 Handler”更容易维护和排障。

