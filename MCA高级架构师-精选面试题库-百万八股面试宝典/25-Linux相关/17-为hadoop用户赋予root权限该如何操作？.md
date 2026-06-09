root是Linux中的超级用户，sudo命令允许普通用户以超级用户（root）身份运行命令，如果为hadoop用户赋予root权限需要在/etc/sudoers文件中做配置。

sudoers文件用于配置哪些用户或用户组可以使用 sudo 命令以提权执行任务的配置文件。

Centos系统中，为hadoop用户赋予root权限操作在/etc/sudoers文件中增加如下内容：

|  |
| --- |
| **#在 root ALL=(ALL) ALL 行下方加入如下内容**  hadoop ALL=(ALL) ALL |

“hadoop ALL=(ALL) ALL”这一行表示 hadoop用户可以在**任何主机上**以**任何用户身份**执行**所有命令**,命令解释如下：

- hadoop: 指定的用户是 hadoop。
- ALL: 表示适用于所有主机，通常用于本地机器的配置。
- (ALL): 表示 hadoop 用户可以以任何身份执行命令，默认情况下是 hadoop 身份。
- ALL: 表示 hadoop 用户可以运行系统上所有的命令。

配置以上完成后，可以切换hadoop用户，验证是否拥有root权限：

|  |
| --- |
| **#切换hadoop用户**  su hadoop    **#查看/root中文件，可以看到hadoop用户权限提升**  sudo ls /root  [sudo] hadoop 的密码：  anaconda-ks.cfg |
