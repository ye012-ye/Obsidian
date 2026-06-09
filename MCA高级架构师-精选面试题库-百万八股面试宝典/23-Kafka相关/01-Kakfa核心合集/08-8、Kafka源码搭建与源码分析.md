# Kafka源码分析环境搭建

使用截止目前为止Kafka的最新版本3.3.1版本的源码进行环境搭建

## Kafka源码下载

从kafka官网下载kafka-3.3.1版本的源码

http://kafka.apache.org/downloads

![](../../assets/e81679386e01c9bb.png)

![](../../assets/03e285989b585a75.png)

解压(要放到英文目录，不然会报一些奇怪的错误)

![](../../assets/6a4b09829a9df9a3.png)

## Scala安装

因为在源码中配置的scala版本是2.13.8

![](../../assets/ccd4c54bc13b17a5.png)

以我们在win上安装Scala 2.13，上官网找到2.13.8版本对应的下载地址

<https://www.scala-lang.org/download/2.13.8.html>

![](../../assets/5036c66515f1a313.png)

然后就可以下载win上的安装包，scala.msi，下载好之后傻瓜式安装就可以了

在cmd中输入scala如果出现如下提示则安装成功

![](../../assets/6c5bd7e9d37f43e9.png)

## idea版本选择与Scala插件

因为最终要使用ide来导入，同时最新版本的kafka源码构建必须是gradle是高版本，所以IDE也必须是高版本才支持高版本的 gradle，所以这里推荐使用IntelliJ IDEA 2020.3.4 版本。

![](../../assets/f0b3c360c0fd00d4.png)

从这里可以看出gradle是6.7，版本已经够支持了。

安装Scala插件。

进入IntelliJ IDEA的这个界面

左侧有一个“Plugins”，搜索scala相关的插件，此时一开始是找不到的，然后点击“search in repositories”，找到一个“Scala”插件，他的类别是“Language”，在线装即可，他会下载之后安装

![](../../assets/2b9ad9f06eefa29e.png)

## Gradle的安装

接着需要安装Gradle，现在国外很多知名的开源项目，Kafka是用Gradle来进行项目的构建了，所以需要安装。

我的IDE的版本支持的是gradle是

Gradle来完成Kafka源码的构建，使用gradle 7.6，从官网下载，解压缩即可，然后配置GRADLE\_HOME和PATH

https://gradle.org/releases/

![](../../assets/e66591b3326f9593.png)

配置环境变量，新建 GRADLE\_HOME 环境变量指向你的 Gradle 解压路径

![](../../assets/d8d38cf3dc48a188.png)

然后将 %GRADLE\_HOME%\bin 添加到 Path 环境变量中，然后点击确定

![](../../assets/d7eb5ae208fa1718.png)

![](../../assets/14a4f75b88c74f0a.png)

验证gradle是否安装成功，打开cmd命令行输入 gradle -v

![](../../assets/058219721000f7c2.png)

最后 验证三个基础的依赖都正确安装了

```plain
java -version
scala -version
gradle -version
```

## 使用Gradle来构建Kafka源码

通过win命令行进入kafka-3.3.1-src目录下，然后执行“gradle idea”为源码导入idea进行构建

这个过程会下载大量的依赖jar包，建议配置 gradle 版本库为阿里源（不然会很慢，同时还可能抛出无法下载错误），同时也要修改对应的配置文件。

编辑Kafka源码目录下的build.gradle文件

### 1、修改阿里源

![](../../assets/56c2d546cdd34270.png)

![](../../assets/8f0f53a06099fed4.png)

![](../../assets/dc217d540aec32f0.png)

```plain
maven { url 'https://maven.aliyun.com/repository/public' }
```

### 2、修改配置（防止构建报错）

```plain
ScalaCompileOptions.metaClass.daemonServer=true
ScalaCompileOptions.metaClass.fork=true
ScalaCompileOptions.metaClass.useAnt=false
ScalaCompileOptions.metaClass.useCompileDaemon=false
```

![](../../assets/02d35fac032b7d26.png)

### 3、构建成功

![](../../assets/f0c7b8841ab65b4a.png)

安装完了在plugins里面就可以找到scala插件了，然后点击“ok”就会提示你重启intellij idea来激活安装好的插件，然后点击里面的那个Import Project按钮即可，选择你的kafka源码所在的目录，选择你构建项目的方式是“gradle”，导入的过程也需要不少的时间，需要耐心等待，会显示的是如下的图：

![](../../assets/4dc0850c135a4900.png)

![](../../assets/926a418487f07622.png)

![](../../assets/04a2df1de9cc7d94.png)

## 在IDEA中启动Kafka

我们肯定是要看到log4j输出的日志的，所以必须把config目录下的log4j.properties给放到src/main/scala目录下去，这样才能看到服务端运行起来的程序打印出来的日志![](../../assets/4657fce55179fa0d.png)

另外需要修改 config目录下的server.properties

![](../../assets/5a003c3845815a6b.png)

![](../../assets/ba72e9bfc2ce1a4d.png)

![](../../assets/eef3c43307a321ba.png)

之前IDE的Scala版本偏老，运行时会出现这个错误

那么手动更新scala的版本

https://plugins.jetbrains.com/plugin/1347-scala/versions/stable

![](../../assets/e131ff1212b9a6dd.png)

![](../../assets/7414f2131fc4a222.png)

缺少包slf4j-nop，导入该包。

![](../../assets/e5df2719bf8b0516.png)

![](../../assets/b2808b601cc05f58.png)

```plain
slf4jnop: "org.slf4j:slf4j-nop:$versions.slf4j",
```

![](../../assets/e0d48f8ee43de406.png)

```plain
 compileOnly libs.slf4jnop
```

![](../../assets/4f1c8d35252e8917.png)
