---
title: ByteBuf 内存管理与泄漏排查
tags:
  - Java
  - Netty
  - ByteBuf
  - 内存管理
created: 2026-06-10
up: "[[00-MOC-Java-Netty从0基础到大神]]"
description: 理解 ByteBuf、readerIndex、writerIndex、引用计数、direct memory 和泄漏排查。
---

# ByteBuf 内存管理与泄漏排查

> [!tip] 本章目标
> 你要敢用 ByteBuf，但也要敬畏它。Netty 性能的一半在 ByteBuf，事故的一半也可能在 ByteBuf。

## ByteBuf 是什么

官方 Javadoc 描述 ByteBuf 是一段可随机访问和顺序访问的字节序列，可以抽象底层的 `byte[]` 或 NIO Buffer。

你可以把它看成：

```text
byte[] + 读指针 + 写指针 + 引用计数 + 池化能力
```

## readerIndex 和 writerIndex

```text
0           readerIndex       writerIndex        capacity
| 已读区域 | 可读区域           | 可写区域          |
```

常用方法：

```java
byteBuf.readInt();
byteBuf.writeInt(123);
byteBuf.readableBytes();
byteBuf.isReadable();
byteBuf.markReaderIndex();
byteBuf.resetReaderIndex();
```

## 创建 ByteBuf

```java
ByteBuf heap = Unpooled.buffer(256);
ByteBuf direct = Unpooled.directBuffer(256);
ByteBuf pooled = ctx.alloc().buffer();
```

> [!success] 推荐
> 在 Handler 中优先使用 `ctx.alloc()` 创建 ByteBuf，让 Netty 根据配置使用合适的 allocator。

## 引用计数

ByteBuf 实现了引用计数。

常用方法：

```java
buf.retain();
buf.release();
buf.refCnt();
```

> [!danger] ByteBuf 泄漏
> 你拿到了 ByteBuf，却没有在合适时机 release，就可能泄漏 direct memory。泄漏不是 Java heap 一定会涨，而是 direct memory 慢慢被吃掉。

## 什么时候需要 release

粗略规则：

1. `SimpleChannelInboundHandler` 默认会释放入站消息。
2. `ChannelInboundHandlerAdapter` 中如果消费了 ByteBuf 且不往后传，要手动 release。
3. 如果 `ctx.fireChannelRead(msg)` 继续传递，就不要在当前 Handler release。
4. 如果 `writeAndFlush(msg)` 写出去，通常交给 Netty 出站流程释放。

```java
@Override
public void channelRead(ChannelHandlerContext ctx, Object msg) {
    ByteBuf buf = (ByteBuf) msg;
    try {
        // read bytes
    } finally {
        buf.release();
    }
}
```

## 泄漏排查

开发环境可以打开：

```bash
-Dio.netty.leakDetection.level=PARANOID
```

生产一般不要长期用最高级别，开销较大。

> [!warning] direct memory 也要监控
> 只看 JVM heap 不够。Netty 大量使用 direct memory，排查时要看 direct memory、allocator 指标、GC、连接数、写缓冲。

## 本章小结

> [!info] 面试表达
> ByteBuf 比 ByteBuffer 更适合网络编程：读写指针分离、支持池化、支持 direct memory、支持引用计数，但也要求开发者理解释放规则。

