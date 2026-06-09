在 Docker 容器运行异常时，查看日志信息是排查问题的关键步骤。Docker 提供了多种命令和方法来获取容器的日志，以下是常用的几种方式：

M

### 1. 使用 `docker logs` 命令查看容器日志

`docker logs` 命令用于获取容器的标准输出（stdout）和标准错误输出（stderr）信息。其基本用法如下：

```bash
docker logs <容器名称或ID>
```

如果只想查看最新的几行日志，可以使用 `--tail` 选项指定行数，例如查看最新的 10 行日志：

```bash
docker logs --tail 10 <容器名称或ID>
```

若需实时查看日志输出，可以使用 `--follow`（或 `-f`）选项：

```bash
docker logs --follow <容器名称或ID>
```

此外，`docker logs` 命令还支持其他选项，如 `--timestamps`（显示时间戳）和 `--details`（显示详细信息）等，具体可参考官方文档 。

S

### 2. 进入容器内部查看日志文件

有些容器内的应用程序可能将日志写入特定的文件，而非标准输出。此时，可以通过 `docker exec` 命令进入容器内部，查看日志文件。首先，使用以下命令获取容器的名称或 ID：

```bash
docker ps
```

然后，使用 `docker exec` 命令进入容器：

```bash
docker exec -it <容器名称或ID> /bin/bash
```

进入容器后，可以使用 `cat`、`less` 或 `tail` 等命令查看日志文件。例如，查看 Nginx 的访问日志：

```bash
cat /var/log/nginx/access.log
```

### 3. 使用 `docker attach` 命令实时查看容器输出

`docker attach` 命令用于附加到正在运行的容器，实时查看其标准输出和标准错误输出。其基本用法如下：

```bash
docker attach <容器名称或ID>
```

需要注意的是，`docker attach` 会附加到容器的主进程（PID 1），如果该进程终止，容器也会停止。因此，在使用 `docker attach` 时，请确保不会意外终止主进程 。

B

### 4. 查看 Docker 守护进程日志

如果容器本身没有明显的错误信息，可能是 Docker 守护进程出现了问题。此时，可以查看 Docker 守护进程的日志。在 Linux 系统上，可以使用以下命令查看：

```bash
journalctl -u docker.service
```

或者查看系统日志文件：

```bash
cat /var/log/syslog
```

​
