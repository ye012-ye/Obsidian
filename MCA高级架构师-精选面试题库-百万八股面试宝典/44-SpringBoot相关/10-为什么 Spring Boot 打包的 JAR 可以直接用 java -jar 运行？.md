Spring Boot 可执行 JAR 能直接运行，源于一整套精心设计的技术机制：M

首先，Spring Boot 使用 Maven/Gradle 插件对项目进行 repackage，将应用主程序类及其依赖收纳在一个 JAR 内部结构中。应用字节码放在 `BOOT-INF/classes/`，依赖 JAR 放在 `BOOT-INF/lib/`，而启动器类存在于 `org/springframework/boot/loader/` 目录中。

其次，`META-INF/MANIFEST.MF` 被设置了两个关键属性：

- `Main-Class`: 指向 Spring Boot 提供的 `JarLauncher`
- `Start-Class`: 指向用户的 `main()` 方法所在类

当执行 `java -jar app.jar` 时，JVM 会调用 `JarLauncher.main()`，它启动一个定制的 `URLClassLoader`：通过 `NestedJarFile` 技术，能够定位并加载 `BOOT-INF/lib/*.jar` 和 `BOOT-INF/classes/` 下的内容，无需提前解压。S

接下来，`JarLauncher` 会反射调用用户的 `Start-Class.main()`，完成 Spring 容器的初始化，包括嵌入式 Web 服务器的启动（如 Tomcat、Jetty 等），使得整个应用能够直接运行为一个独立服务。

此外，Spring Boot 还支持打包成 “fully executable JAR”，在原始 JAR 前附加一个 shell 脚本头，使其能被 Linux 当成脚本执行（如 `./app.jar start`），适用于 `systemd` 或 `init.d` 部署环境。B
