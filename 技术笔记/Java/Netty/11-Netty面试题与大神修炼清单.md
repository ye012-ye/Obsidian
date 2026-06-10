---
title: Netty 面试题与大神修炼清单
tags:
  - Java
  - Netty
  - 面试
created: 2026-06-10
up: "[[00-MOC-Java-Netty从0基础到大神]]"
description: Netty 高频面试题、回答框架、避坑清单和持续修炼路线。
---

# Netty 面试题与大神修炼清单

> [!tip] 本章目标
> Netty 面试别只说“异步非阻塞”。要讲到线程模型、Pipeline、ByteBuf、协议边界、生产避坑。

## 高频面试题

### 1. Netty 是什么？

Netty 是异步事件驱动的网络应用框架，用于快速开发高性能、可维护的协议服务器和客户端。

### 2. Netty 为什么快？

回答：

1. 基于 NIO 非阻塞 I/O。
2. Reactor 事件驱动模型。
3. EventLoop 单线程处理 Channel 事件，减少锁竞争。
4. ByteBuf 支持池化和 direct memory。
5. Pipeline/Handler 模型让协议处理清晰可组合。
6. 支持 Linux native transport。

### 3. BossGroup 和 WorkerGroup 区别？

BossGroup 负责接收连接；WorkerGroup 负责处理已建立连接的读写事件。

### 4. EventLoop 为什么不能阻塞？

一个 EventLoop 会负责多个 Channel。阻塞一个 EventLoop，会影响它管理的所有连接。

### 5. ChannelPipeline 是什么？

Pipeline 是 Handler 链，负责组织入站和出站事件。常见顺序是拆包、解码、认证、业务、编码、写出。

### 6. ByteBuf 和 ByteBuffer 区别？

ByteBuf 读写指针分离，API 更适合网络编程，支持池化、direct memory、引用计数和更灵活的扩容。

### 7. 什么是粘包和半包？

TCP 是字节流协议，没有消息边界。一次写入不保证一次读取，所以应用层必须通过固定长度、分隔符或长度字段定义边界。

### 8. 如何避免 ByteBuf 泄漏？

明确消息所有权；消费后不传递就 release；传递给下一个 Handler 就不要释放；开发环境开启 leak detection。

### 9. Netty 如何做心跳？

使用 `IdleStateHandler` 触发空闲事件，服务端根据读空闲关闭僵尸连接，根据写空闲发送 ping。

### 10. Netty 4.2 升级要注意什么？

依赖统一、先升最新 4.1.x、关注 TLS 主机名校验默认变化、allocator 默认变化、direct memory 和 GC 监控。

## 避坑清单

> [!danger] 面试和生产都常见
> - 在 EventLoop 里跑阻塞业务。
> - 以为 TCP 一次 read 就是一条消息。
> - Handler 有成员变量却标 `@Sharable`。
> - ByteBuf 不 release。
> - 不设置最大帧长度。
> - 不处理写缓冲不可写。
> - 重连没有退避。
> - 心跳太频繁或太慢。
> - 只会 demo，不会讲生产容量。

## 修炼路线

第一阶段：会跑。

1. Echo Server。
2. Echo Client。
3. Pipeline。
4. Handler。
5. ByteBuf 基本读写。

第二阶段：会写协议。

1. 长度字段协议。
2. 自定义编码器。
3. 自定义解码器。
4. 心跳。
5. 登录认证。

第三阶段：会做系统。

1. 聊天室。
2. IM 网关。
3. RPC 协议。
4. 网关转发。
5. 多节点连接路由。

第四阶段：会排障。

1. EventLoop 阻塞。
2. direct memory 泄漏。
3. 写缓冲积压。
4. 连接暴涨。
5. native transport 与系统参数。

## 本专题回顾

回到入口：[[00-MOC-Java-Netty从0基础到大神]]

