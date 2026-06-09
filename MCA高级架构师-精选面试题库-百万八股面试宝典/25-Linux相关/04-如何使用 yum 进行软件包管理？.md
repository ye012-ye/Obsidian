在 CentOS 或 RHEL 中管理 RPM 包典型地使用 `yum` 工具（在 RHEL 8 中 `yum` 实际上是对 `dnf` 的别名）。下面逐条介绍常用命令及其实际用途：

#### **安装软件包**

执行以下命令可以安装指定软件包及其依赖，比如安装 Apache 服务：

```bash
sudo yum install httpd
```

`yum` 会自动解析依赖并安装所需模块，如果不想确认可添加 `-y` 参数。同时也支持使用 `yum install /path/to/file.rpm` 从本地 RPM 文件安装。

#### **更新软件包与系统**

- 更新所有软件包：

```bash
sudo yum update
```

- 更新指定软件包：

```plain
sudo yum update <package_name>
```

- 检查可用更新：

```bash
yum check-update
```

此外，还支持 `yum update --security` 仅应用安全补丁。

#### **卸载软件包**

使用以下命令移除软件包：

```bash
sudo yum remove package_name
```

这将删除该软件及其依赖关系，而保留配置文件。要同时删除未使用依赖可执行 `yum autoremove`。

#### **降级与重装软件包**

- 降级回旧版本：

```bash
sudo yum downgrade package_name
```

- 重新安装当前版本：

```bash
sudo yum reinstall package_name
```

适用于修复损坏软件包或回退不稳定升级。

#### **搜索与查看软件信息**

- 搜索匹配关键词的软件包：

```bash
yum search <keyword>
```

- 查看详细信息（如版本、依赖、简介）：

```bash
yum info package_name
```

- 查看依赖列表：

```bash
yum deplist package_name
```

便于判断是否安装满足依赖及功能要求。

#### **管理仓库与缓存**

- 列出所有仓库状态：

```bash
yum repolist all
```

- 清理缓存：

```bash
sudo yum clean all
```

可刷新元数据，解决缓存一致性问题。

#### **事务历史与回滚操作**

- 查看历史安装、更新与删除记录：

```bash
yum history list
```

- 查看某次事务详情：

```bash
yum history info <ID>
```

- 撤销指定事务：

```bash
sudo yum history undo <ID>
```

- 重做之前撤销事务：

```bash
sudo yum history redo <ID>
```

非常适用于回退错误操作或变更。
