# Linux 命令大全

---

## 一、文件与目录操作

| 命令 | 描述 | 示例 |
|------|------|------|
| `ls` | 列出目录内容 | `ls -la`（显示所有文件含详情） |
| `cd` | 切换工作目录 | `cd /home/user` |
| `pwd` | 显示当前工作目录的绝对路径 | `pwd` |
| `mkdir` | 创建目录 | `mkdir -p a/b/c`（递归创建） |
| `rmdir` | 删除空目录 | `rmdir mydir` |
| `rm` | 删除文件或目录 | `rm -rf dir/`（强制递归删除） |
| `cp` | 复制文件或目录 | `cp -r src/ dest/`（递归复制） |
| `mv` | 移动/重命名文件或目录 | `mv old.txt new.txt` |
| `touch` | 创建空文件或更新时间戳 | `touch file.txt` |
| `find` | 按条件搜索文件 | `find / -name "*.log" -mtime -7` |
| `locate` | 快速定位文件（基于数据库） | `locate nginx.conf` |
| `tree` | 以树状结构显示目录 | `tree -L 2`（显示 2 层） |
| `ln` | 创建链接 | `ln -s /path/to/file link`（软链接） |
| `stat` | 显示文件详细信息（大小、权限、时间） | `stat file.txt` |
| `file` | 检测文件类型 | `file image.png` |
| `basename` | 提取文件名 | `basename /path/to/file.txt` → `file.txt` |
| `dirname` | 提取目录路径 | `dirname /path/to/file.txt` → `/path/to` |

---

## 二、文件内容查看与处理

| 命令 | 描述 | 示例 |
|------|------|------|
| `cat` | 查看文件全部内容 | `cat file.txt` |
| `tac` | 反向逐行显示文件内容 | `tac file.txt` |
| `head` | 查看文件头部 N 行 | `head -n 20 file.txt` |
| `tail` | 查看文件尾部 N 行 | `tail -f log.txt`（实时追踪） |
| `less` | 分页查看文件（支持前后翻页） | `less largefile.log` |
| `more` | 分页查看文件（只能向前） | `more file.txt` |
| `grep` | 按正则匹配搜索文本 | `grep -rn "error" /var/log/` |
| `awk` | 文本列处理与格式化 | `awk '{print $1, $3}' file.txt` |
| `sed` | 流式文本编辑（替换、删除等） | `sed -i 's/old/new/g' file.txt` |
| `sort` | 对文件内容排序 | `sort -k2 -n file.txt`（按第 2 列数字排序） |
| `uniq` | 去除相邻的重复行 | `sort file | uniq -c`（统计重复次数） |
| `wc` | 统计行数、单词数、字节数 | `wc -l file.txt`（统计行数） |
| `cut` | 按分隔符/列截取文本 | `cut -d: -f1 /etc/passwd` |
| `tr` | 字符替换或删除 | `echo "HELLO" \| tr 'A-Z' 'a-z'` |
| `diff` | 比较两个文件的差异 | `diff file1.txt file2.txt` |
| `tee` | 同时输出到屏幕和文件 | `echo "hi" \| tee output.txt` |
| `xargs` | 将标准输入转为命令参数 | `find . -name "*.tmp" \| xargs rm` |

---

## 三、用户与权限管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `whoami` | 显示当前登录用户名 | `whoami` |
| `id` | 显示用户 UID、GID 和所属组 | `id root` |
| `useradd` | 创建新用户 | `useradd -m -s /bin/bash john` |
| `userdel` | 删除用户 | `userdel -r john`（同时删除主目录） |
| `usermod` | 修改用户属性 | `usermod -aG docker john`（加入 docker 组） |
| `passwd` | 修改用户密码 | `passwd john` |
| `groupadd` | 创建用户组 | `groupadd devteam` |
| `groupdel` | 删除用户组 | `groupdel devteam` |
| `chmod` | 修改文件权限 | `chmod 755 script.sh` |
| `chown` | 修改文件所有者和组 | `chown user:group file.txt` |
| `chgrp` | 修改文件所属组 | `chgrp devteam file.txt` |
| `su` | 切换用户 | `su - root` |
| `sudo` | 以超级用户权限执行命令 | `sudo apt update` |
| `visudo` | 安全编辑 sudoers 配置 | `visudo` |

---

## 四、进程管理

| 命令        | 描述               | 示例                               |
| --------- | ---------------- | -------------------------------- |
| `ps`      | 查看当前进程快照         | `ps aux`（显示所有进程）                 |
| `top`     | 实时动态显示进程状态       | `top -d 1`（每秒刷新）                 |
| `htop`    | 增强版 top（交互式）     | `htop`                           |
| `kill`    | 发送信号终止进程         | `kill -9 12345`（强制杀死 PID 12345）  |
| `killall` | 按进程名终止所有匹配进程     | `killall nginx`                  |
| `pkill`   | 按名称/条件杀死进程       | `pkill -f "java -jar"`           |
| `pgrep`   | 按名称搜索进程 PID      | `pgrep -l sshd`                  |
| `nohup`   | 使进程在终端关闭后继续运行    | `nohup ./script.sh &`            |
| `bg`      | 将挂起的进程放到后台运行     | `bg %1`                          |
| `fg`      | 将后台进程调回前台        | `fg %1`                          |
| `jobs`    | 列出当前 shell 的后台作业 | `jobs -l`                        |
| `nice`    | 以指定优先级启动进程       | `nice -n 10 ./task.sh`           |
| `renice`  | 修改运行中进程的优先级      | `renice -5 -p 12345`             |
| `lsof`    | 列出进程打开的文件        | `lsof -i :8080`（查看占用 8080 端口的进程） |

---

## 五、网络管理

| 命令 | 描述 | 示例 |
|------|------|------|
| `ip` | 显示/管理网络接口和路由 | `ip addr show`、`ip route` |
| `ifconfig` | 查看/配置网络接口（旧版） | `ifconfig eth0` |
| `ping` | 测试与目标主机的连通性 | `ping -c 4 google.com` |
| `curl` | 发送 HTTP 请求 | `curl -X POST -d '{}' url` |
| `wget` | 下载文件 | `wget -O file.zip url` |
| `ss` | 查看 socket 统计信息（替代 netstat） | `ss -tlnp`（监听中的 TCP 端口） |
| `netstat` | 显示网络连接和端口（旧版） | `netstat -tulnp` |
| `traceroute` | 追踪网络路由路径 | `traceroute google.com` |
| `nslookup` | DNS 查询 | `nslookup example.com` |
| `dig` | DNS 高级查询 | `dig example.com A +short` |
| `host` | 简易 DNS 查询 | `host example.com` |
| `scp` | 通过 SSH 远程复制文件 | `scp file.txt user@host:/path/` |
| `rsync` | 高效远程/本地文件同步 | `rsync -avz src/ user@host:dest/` |
| `ssh` | 远程安全登录 | `ssh -p 22 user@192.168.1.1` |
| `firewall-cmd` | 管理 firewalld 防火墙 | `firewall-cmd --list-all` |
| `iptables` | 配置内核防火墙规则 | `iptables -L -n` |
| `nc` (netcat) | TCP/UDP 连接与端口扫描 | `nc -zv host 80`（测试端口） |
| `tcpdump` | 抓取网络数据包 | `tcpdump -i eth0 port 80` |

---

## 六、磁盘与存储

| 命令 | 描述 | 示例 |
|------|------|------|
| `df` | 查看文件系统磁盘使用情况 | `df -h`（人类可读格式） |
| `du` | 查看文件/目录占用空间 | `du -sh /var/log`（汇总大小） |
| `mount` | 挂载文件系统 | `mount /dev/sdb1 /mnt/usb` |
| `umount` | 卸载文件系统 | `umount /mnt/usb` |
| `fdisk` | 磁盘分区管理 | `fdisk -l`（列出所有分区） |
| `lsblk` | 列出所有块设备（磁盘、分区） | `lsblk` |
| `blkid` | 显示块设备 UUID 和类型 | `blkid /dev/sda1` |
| `mkfs` | 格式化磁盘分区 | `mkfs.ext4 /dev/sdb1` |
| `fsck` | 检查和修复文件系统 | `fsck /dev/sda1` |
| `dd` | 底层数据复制/磁盘镜像 | `dd if=/dev/sda of=disk.img bs=4M` |

---

## 七、压缩与归档

| 命令 | 描述 | 示例 |
|------|------|------|
| `tar` | 打包/解包归档文件 | `tar -czvf archive.tar.gz dir/`（压缩） |
| `tar` (解压) | 解压 tar 归档 | `tar -xzvf archive.tar.gz`（解压） |
| `gzip` | 压缩文件（.gz） | `gzip file.txt` |
| `gunzip` | 解压 .gz 文件 | `gunzip file.txt.gz` |
| `zip` | 压缩为 .zip 格式 | `zip -r archive.zip dir/` |
| `unzip` | 解压 .zip 文件 | `unzip archive.zip -d /dest/` |
| `bzip2` | 压缩文件（.bz2，压缩率更高） | `bzip2 file.txt` |
| `xz` | 压缩文件（.xz，最高压缩率） | `xz file.txt` |

---

## 八、系统信息与监控

| 命令 | 描述 | 示例 |
|------|------|------|
| `uname` | 显示系统/内核信息 | `uname -a` |
| `hostname` | 显示/设置主机名 | `hostname` |
| `uptime` | 显示系统运行时间和负载 | `uptime` |
| `date` | 显示/设置系统日期时间 | `date "+%Y-%m-%d %H:%M:%S"` |
| `cal` | 显示日历 | `cal 2026` |
| `free` | 查看内存使用情况 | `free -h` |
| `vmstat` | 虚拟内存/CPU/IO 统计 | `vmstat 1 5`（每秒采样，共 5 次） |
| `iostat` | 磁盘 I/O 统计 | `iostat -x 1` |
| `dmesg` | 查看内核环形缓冲区日志 | `dmesg \| tail -50` |
| `journalctl` | 查看 systemd 日志 | `journalctl -u nginx --since today` |
| `last` | 显示最近登录记录 | `last -10` |
| `who` | 显示当前登录用户 | `who` |
| `w` | 显示登录用户及其活动 | `w` |
| `env` | 显示所有环境变量 | `env` |
| `export` | 设置环境变量 | `export PATH=$PATH:/opt/bin` |

---

## 九、服务与启动管理 (systemd)

| 命令 | 描述 | 示例 |
|------|------|------|
| `systemctl start` | 启动服务 | `systemctl start nginx` |
| `systemctl stop` | 停止服务 | `systemctl stop nginx` |
| `systemctl restart` | 重启服务 | `systemctl restart nginx` |
| `systemctl reload` | 重新加载服务配置（不中断） | `systemctl reload nginx` |
| `systemctl status` | 查看服务运行状态 | `systemctl status nginx` |
| `systemctl enable` | 设置开机自启 | `systemctl enable nginx` |
| `systemctl disable` | 取消开机自启 | `systemctl disable nginx` |
| `systemctl list-units` | 列出所有活跃的服务单元 | `systemctl list-units --type=service` |
| `systemctl daemon-reload` | 重新加载 systemd 配置 | `systemctl daemon-reload` |

---

## 十、包管理

### CentOS / RHEL (yum/dnf)

| 命令 | 描述 | 示例 |
|------|------|------|
| `yum install` | 安装软件包 | `yum install -y nginx` |
| `yum remove` | 卸载软件包 | `yum remove nginx` |
| `yum update` | 更新所有软件包 | `yum update` |
| `yum search` | 搜索软件包 | `yum search java` |
| `yum list installed` | 列出已安装的包 | `yum list installed` |
| `rpm -ivh` | 安装 RPM 包 | `rpm -ivh package.rpm` |
| `rpm -qa` | 列出所有已安装 RPM 包 | `rpm -qa \| grep java` |

### Ubuntu / Debian (apt)

| 命令 | 描述 | 示例 |
|------|------|------|
| `apt update` | 刷新软件源索引 | `sudo apt update` |
| `apt install` | 安装软件包 | `sudo apt install -y nginx` |
| `apt remove` | 卸载软件包 | `sudo apt remove nginx` |
| `apt upgrade` | 升级所有已安装包 | `sudo apt upgrade` |
| `apt search` | 搜索软件包 | `apt search nginx` |
| `dpkg -i` | 安装 deb 包 | `sudo dpkg -i package.deb` |
| `dpkg -l` | 列出已安装包 | `dpkg -l \| grep nginx` |

---

## 十一、其他实用命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `alias` | 创建命令别名 | `alias ll='ls -la'` |
| `history` | 查看历史命令 | `history \| grep ssh` |
| `crontab` | 定时任务管理 | `crontab -e`（编辑定时任务） |
| `watch` | 定期重复执行命令 | `watch -n 2 df -h`（每 2 秒执行） |
| `screen` | 终端会话管理（可断开重连） | `screen -S mysession` |
| `tmux` | 终端复用器（更强大） | `tmux new -s work` |
| `echo` | 打印文本到标准输出 | `echo $HOME` |
| `source` | 在当前 shell 中执行脚本 | `source ~/.bashrc` |
| `which` | 查找命令的可执行文件路径 | `which java` |
| `whereis` | 查找命令的二进制/源码/手册路径 | `whereis nginx` |
| `man` | 查看命令手册 | `man ls` |
| `shutdown` | 关机/重启 | `shutdown -r now`（立即重启） |
| `reboot` | 重启系统 | `reboot` |
