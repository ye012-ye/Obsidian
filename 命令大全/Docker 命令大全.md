# Docker 命令大全

---

## 一、镜像管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker images` | 列出本地所有镜像 | `docker images` |
| `docker pull` | 从仓库拉取镜像 | `docker pull nginx:latest` |
| `docker push` | 将镜像推送到仓库 | `docker push myrepo/myapp:v1` |
| `docker build` | 通过 Dockerfile 构建镜像 | `docker build -t myapp:v1 .` |
| `docker tag` | 给镜像打标签 | `docker tag myapp:v1 myrepo/myapp:v1` |
| `docker rmi` | 删除一个或多个镜像 | `docker rmi nginx:latest` |
| `docker image prune` | 清理无用的悬空镜像 | `docker image prune -a`（清理所有未使用的） |
| `docker save` | 将镜像导出为 tar 文件 | `docker save -o nginx.tar nginx:latest` |
| `docker load` | 从 tar 文件加载镜像 | `docker load -i nginx.tar` |
| `docker history` | 查看镜像构建历史（各层信息） | `docker history nginx:latest` |
| `docker inspect` | 查看镜像详细信息（JSON） | `docker inspect nginx:latest` |
| `docker search` | 在 Docker Hub 搜索镜像 | `docker search redis` |

---

## 二、容器生命周期管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker run` | 创建并启动一个新容器 | `docker run -d --name web -p 80:80 nginx` |
| `docker create` | 创建容器但不启动 | `docker create --name web nginx` |
| `docker start` | 启动已停止的容器 | `docker start web` |
| `docker stop` | 优雅停止运行中的容器 | `docker stop web` |
| `docker restart` | 重启容器 | `docker restart web` |
| `docker kill` | 强制终止容器 | `docker kill web` |
| `docker rm` | 删除已停止的容器 | `docker rm web` |
| `docker rm -f` | 强制删除运行中的容器 | `docker rm -f web` |
| `docker pause` | 暂停容器中所有进程 | `docker pause web` |
| `docker unpause` | 恢复暂停的容器 | `docker unpause web` |
| `docker rename` | 重命名容器 | `docker rename old_name new_name` |
| `docker update` | 更新容器配置（资源限制等） | `docker update --memory 512m web` |
| `docker wait` | 阻塞直到容器停止，输出退出码 | `docker wait web` |

---

## 三、`docker run` 常用参数详解

| 参数 | 描述 | 示例 |
|------|------|------|
| `-d` | 后台运行（detached 模式） | `docker run -d nginx` |
| `-it` | 交互式终端（进入容器 shell） | `docker run -it ubuntu /bin/bash` |
| `--name` | 指定容器名称 | `docker run --name myapp nginx` |
| `-p` | 端口映射（宿主机:容器） | `-p 8080:80` |
| `-P` | 随机映射所有暴露端口 | `docker run -P nginx` |
| `-v` | 挂载数据卷（宿主机:容器） | `-v /host/data:/container/data` |
| `--mount` | 更详细的挂载方式 | `--mount type=bind,src=/host,dst=/app` |
| `-e` | 设置环境变量 | `-e MYSQL_ROOT_PASSWORD=123456` |
| `--env-file` | 从文件加载环境变量 | `--env-file .env` |
| `--network` | 指定容器加入的网络 | `--network my-net` |
| `--restart` | 设置重启策略 | `--restart=always`（总是自动重启） |
| `--rm` | 容器停止后自动删除 | `docker run --rm nginx` |
| `-w` | 设置容器内工作目录 | `-w /app` |
| `--cpus` | 限制 CPU 使用 | `--cpus=1.5` |
| `-m` / `--memory` | 限制内存使用 | `-m 512m` |
| `--privileged` | 赋予容器特权模式 | `docker run --privileged ...` |
| `--link` | 连接到另一个容器（旧版） | `--link db:mysql`（建议用 network） |
| `--hostname` | 设置容器主机名 | `--hostname myhost` |

---

## 四、容器状态查看与调试

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker ps` | 列出运行中的容器 | `docker ps` |
| `docker ps -a` | 列出所有容器（含已停止） | `docker ps -a` |
| `docker logs` | 查看容器日志 | `docker logs -f --tail 100 web` |
| `docker inspect` | 查看容器详细配置（JSON） | `docker inspect web` |
| `docker top` | 查看容器内运行的进程 | `docker top web` |
| `docker stats` | 实时监控容器资源使用 | `docker stats`（所有容器） |
| `docker port` | 查看容器端口映射 | `docker port web` |
| `docker diff` | 查看容器文件系统变更 | `docker diff web` |
| `docker exec` | 在运行中的容器内执行命令 | `docker exec -it web /bin/bash` |
| `docker attach` | 附着到容器主进程（慎用） | `docker attach web` |
| `docker cp` | 宿主机与容器之间复制文件 | `docker cp web:/app/log.txt ./` |
| `docker export` | 导出容器文件系统为 tar | `docker export web > web.tar` |
| `docker import` | 从 tar 创建镜像 | `docker import web.tar myimage:v1` |
| `docker commit` | 将容器变更提交为新镜像 | `docker commit web myapp:snapshot` |

---

## 五、Docker Compose

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker compose up` | 构建并启动所有服务 | `docker compose up -d` |
| `docker compose down` | 停止并移除所有容器和网络 | `docker compose down` |
| `docker compose down -v` | 同上 + 删除数据卷 | `docker compose down -v` |
| `docker compose build` | 构建/重新构建服务镜像 | `docker compose build` |
| `docker compose start` | 启动已存在的服务 | `docker compose start` |
| `docker compose stop` | 停止运行中的服务 | `docker compose stop` |
| `docker compose restart` | 重启服务 | `docker compose restart web` |
| `docker compose ps` | 列出 Compose 管理的容器 | `docker compose ps` |
| `docker compose logs` | 查看服务日志 | `docker compose logs -f web` |
| `docker compose exec` | 在服务容器中执行命令 | `docker compose exec web bash` |
| `docker compose pull` | 拉取服务依赖的镜像 | `docker compose pull` |
| `docker compose config` | 验证并查看合并后的配置 | `docker compose config` |
| `docker compose top` | 查看各服务容器的进程 | `docker compose top` |
| `docker compose scale` | 指定服务副本数 | `docker compose up --scale web=3` |

---

## 六、数据卷管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker volume create` | 创建数据卷 | `docker volume create mydata` |
| `docker volume ls` | 列出所有数据卷 | `docker volume ls` |
| `docker volume inspect` | 查看数据卷详细信息 | `docker volume inspect mydata` |
| `docker volume rm` | 删除数据卷 | `docker volume rm mydata` |
| `docker volume prune` | 清理所有未使用的数据卷 | `docker volume prune` |

### 挂载方式对比

| 类型 | 特点 | 示例 |
|------|------|------|
| **bind mount** | 挂载宿主机指定路径，直接映射 | `-v /host/path:/container/path` |
| **volume** | Docker 管理的数据卷，推荐用于持久化 | `-v myvolume:/container/path` |
| **tmpfs** | 存储在内存中，容器停止后消失 | `--tmpfs /tmp` |

---

## 七、网络管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker network create` | 创建自定义网络 | `docker network create my-net` |
| `docker network ls` | 列出所有网络 | `docker network ls` |
| `docker network inspect` | 查看网络详细信息 | `docker network inspect my-net` |
| `docker network rm` | 删除网络 | `docker network rm my-net` |
| `docker network connect` | 将容器连接到网络 | `docker network connect my-net web` |
| `docker network disconnect` | 将容器从网络断开 | `docker network disconnect my-net web` |
| `docker network prune` | 清理所有未使用的网络 | `docker network prune` |

### 网络驱动类型

| 驱动 | 描述 |
|------|------|
| `bridge` | 默认驱动，容器通过虚拟网桥通信（单机） |
| `host` | 容器直接使用宿主机网络栈，无隔离 |
| `none` | 无网络，完全隔离 |
| `overlay` | 跨主机容器通信（Swarm 模式） |
| `macvlan` | 为容器分配 MAC 地址，接入物理网络 |

---

## 八、系统与清理

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker system df` | 查看 Docker 磁盘使用概况 | `docker system df` |
| `docker system prune` | 一键清理所有未使用资源 | `docker system prune -a --volumes` |
| `docker system info` | 显示 Docker 系统信息 | `docker system info` |
| `docker version` | 显示 Docker 版本 | `docker version` |
| `docker info` | 显示 Docker 详细系统信息 | `docker info` |
| `docker events` | 实时监听 Docker 事件 | `docker events --since 1h` |
| `docker container prune` | 清理所有已停止的容器 | `docker container prune` |
| `docker image prune` | 清理悬空镜像 | `docker image prune` |

---

## 九、Docker Registry（仓库）

| 命令 | 描述 | 示例 |
|------|------|------|
| `docker login` | 登录镜像仓库 | `docker login registry.example.com` |
| `docker logout` | 登出镜像仓库 | `docker logout` |
| `docker push` | 推送镜像到仓库 | `docker push myrepo/myapp:v1` |
| `docker pull` | 从仓库拉取镜像 | `docker pull myrepo/myapp:v1` |

### 私有仓库搭建

```bash
# 启动本地 Registry
docker run -d -p 5000:5000 --name registry registry:2

# 推送镜像到本地仓库
docker tag myapp:v1 localhost:5000/myapp:v1
docker push localhost:5000/myapp:v1
```

---

## 十、Dockerfile 常用指令

| 指令 | 描述 | 示例 |
|------|------|------|
| `FROM` | 指定基础镜像 | `FROM openjdk:17-slim` |
| `WORKDIR` | 设置工作目录 | `WORKDIR /app` |
| `COPY` | 复制文件到镜像中 | `COPY target/*.jar app.jar` |
| `ADD` | 复制文件（支持 URL 和自动解压 tar） | `ADD app.tar.gz /app/` |
| `RUN` | 构建时执行命令 | `RUN apt-get update && apt-get install -y curl` |
| `CMD` | 容器启动时默认执行的命令 | `CMD ["java", "-jar", "app.jar"]` |
| `ENTRYPOINT` | 容器入口点（不易被覆盖） | `ENTRYPOINT ["java", "-jar"]` |
| `ENV` | 设置环境变量 | `ENV JAVA_OPTS="-Xmx512m"` |
| `ARG` | 构建时参数（仅构建阶段可用） | `ARG VERSION=1.0` |
| `EXPOSE` | 声明容器监听的端口 | `EXPOSE 8080` |
| `VOLUME` | 声明数据卷挂载点 | `VOLUME /data` |
| `USER` | 指定运行用户 | `USER appuser` |
| `HEALTHCHECK` | 容器健康检查 | `HEALTHCHECK CMD curl -f http://localhost/ \|\| exit 1` |
| `LABEL` | 添加元数据标签 | `LABEL maintainer="dev@example.com"` |
| `MULTI-STAGE` | 多阶段构建（减小镜像体积） | `FROM maven AS build` → `FROM openjdk` |

### Dockerfile 最佳实践示例

```dockerfile
# ---- 多阶段构建：Java 应用 ----
# 第一阶段：构建
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 第二阶段：运行（最终镜像更小）
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 十一、常用实战组合

```bash
# 查看所有容器（包含已停止的）ID
docker ps -aq

# 停止所有运行中的容器
docker stop $(docker ps -q)

# 删除所有已停止的容器
docker rm $(docker ps -aq)

# 删除所有 <none> 悬空镜像
docker rmi $(docker images -f "dangling=true" -q)

# 一键清理：停止的容器 + 未使用的镜像 + 未使用的网络 + 数据卷
docker system prune -a --volumes

# 查看容器 IP 地址
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 容器名

# 进入容器 shell
docker exec -it 容器名 /bin/sh

# 实时查看容器最新 200 行日志
docker logs -f --tail 200 容器名

# 复制容器内文件到宿主机
docker cp 容器名:/path/in/container /host/path
```
