要将 Docker 镜像上传至 Docker Hub，需遵循以下步骤：M

### 1. 创建 Docker Hub 仓库

首先，登录 Docker Hub（https://hub.docker.com/）。在个人主页或组织页面，点击“Create Repository”按钮。

- **Repository Name**：为仓库命名，如 `myapp`。
- **Description**：可选，填写仓库的描述信息。
- **Visibility**：选择 Public（公开）或 Private（私有），根据需要设置。

完成后，点击“Create”按钮，创建仓库。

### 2. 构建 Docker 镜像

在本地机器上，进入包含 `Dockerfile` 的目录，使用以下命令构建镜像：

```bash
docker build -t <username>/myapp:latest .
```

其中，`<username>` 是您的 Docker Hub 用户名，`myapp` 是镜像名称，`latest` 是标签。

构建完成后，使用 `docker images` 命令确认镜像已成功创建。

S

### 3. 登录 Docker Hub

在终端中执行以下命令：

```bash
docker login
```

系统会提示输入 Docker Hub 的用户名和密码。登录成功后，您将看到“Login Succeeded”的提示。

### 4. 标记镜像

为了将本地镜像与 Docker Hub 仓库关联，使用以下命令：

```bash
docker tag myapp:latest <username>/myapp:latest
```

这将为镜像添加一个标签，使其与 Docker Hub 上的仓库匹配。

### 5. 推送镜像到 Docker Hub

使用以下命令将镜像推送到 Docker Hub：

```bash
docker push <username>/myapp:latest
```

推送过程中，Docker 会逐层上传镜像的每个层，并计算每个层的 SHA256 哈希值。上传完成后，可以在 Docker Hub 上看到已上传的镜像。

B
