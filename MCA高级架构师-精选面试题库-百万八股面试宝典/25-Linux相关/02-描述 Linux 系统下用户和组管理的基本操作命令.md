在 Linux 下，用户与组管理是确保系统安全与权限控制的核心操作。以下介绍常见命令、用途及示例。

#### **创建与删除用户**

使用 `useradd` 可以创建新用户，例如执行 `sudo useradd testuser` 会生成一个基本用户账户。接着通过 `sudo passwd testuser` 设置用户登录密码，从而激活该账户。若需删除用户，可使用 `sudo userdel username`，如删除 testuser；如再加上 `-r` 参数（`sudo userdel -r testuser`）则连用户主目录一并删除。S

#### **修改用户属性与管理组成员**

`usermod` 用于修改现有用户属性，包括用户名、Shell、主目录及组成员等。例如，`sudo usermod -aG devgroup testuser` 会将 testuser 添加至 devgroup，同时保留其已有组成员身份。若不加 `-a` 参数（只用 `-G`），会替换原有组成员信息，因此常需组合使用 `-aG`。M

#### **创建与删除组**

`groupadd` 用于新建组，例如 `sudo groupadd testgroup`。删除组则使用 `groupdel testgroup`，该命令仅移除组定义，不影响组内用户的账号。B

#### **查看组成员与用户所属组**

使用 `groups username` 或直接执行 `groups` 可列出指定用户或当前用户所属的所有组。 若希望查看系统中所有组，可通过 `cat /etc/group` 或 `getent group` 实现。

#### **更改文件/目录的用户或组归属**

权限管理中常用 `chown`（改变文件或目录的用户与组归属，例如 `sudo chown testuser:testgroup file.txt`）以及 `chgrp`（仅改变所属组，例如 `sudo chgrp testgroup file.txt`）。这两者在权限控制与协作场景中非常高效。

#### **切换用户执行操作**

使用 `su username`（切换为用户名的 shell），或 `su – username`（模拟完整登录环境），可快速测试或切换用户上下文。若只需执行指定命令，可使用 sudo 授权方式。
