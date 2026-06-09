**一、Docker 在 Linux 上的快速安装流程**  
首先，卸载系统中可能存在的旧版 Docker 包，比如 `docker.io`、`docker-compose`、`podman-docker` 等，避免冲突。然后使用官方仓库安装方式（以 Ubuntu 为例）进行安装：更新 apt 并添加 Docker 的 GPG 公钥与源，接着执行 `sudo apt-get update` 后安装 `docker-ce docker-ce-cli containerd.io docker-compose-plugin`。安装完成后，通过 `sudo docker run hello-world` 验证 Docker 是否正常运行。

M

对于 RHEL/CentOS 系统，可使用 `yum install docker-ce`，安装后使用 `systemctl start docker` 启动服务，并执行 `systemctl enable docker` 设置开机自启。

S

如果是测试或快速部署环境，也可使用官方 “quick install” 脚本 `curl -fsSL https://get.docker.com | sh`，此方式适合需要非交互式安装场景。

**二、配置国内镜像加速**  
由于国内访问 Docker Hub 慢或失败，建议配置国内镜像加速器。在 `/etc/docker/daemon.json` 中添加如下内容：

```json
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```

保存后执行 `systemctl daemon-reload` 和 `systemctl restart docker` 使配置生效。这样拉取镜像速度将显著提升。

**三、Docker 常用命令简述**  
安装并启动后，可执行以下关键命令：

- 查看服务状态：`systemctl status docker` 或 `docker version`。
- 搜索镜像：`docker search <镜像名>`；拉取镜像：`docker pull nginx:latest`。
- 管理容器：使用 `docker run` 启动容器（支持参数如 `-d`, `-p`, `--name` 等）、`docker stop` 停止、`docker rm` 删除。
- 查看容器列表：`docker ps`（运行中），`docker ps -a`（所有容器）；查看镜像：`docker images`。
- 日志和资源监控：`docker logs -f <容器ID>` 查看日志，`docker stats` 实时查看容器资源使用情况。

此外，为了容器在主机重启后自动启动，可以在创建时加入 `--restart=always`，或对现有容器执行 `docker update --restart=always <容器ID>`。
