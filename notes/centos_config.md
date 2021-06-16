# Centos 服务器配置流程

## 创建非root用户

```shell
adduser xshop
```
根据提示输入用户密码即可

切换至root账户，为sudo文件增加写权限，默认是读权限

编辑sudo文件 在root ALL=(ALL) ALL 加入
```shell
xshop ALL=(ALL) ALL
```

## 关闭SELINUX
查看selinux状态
```sehll
sestatus
```
如果状态不是disabled, 修改 配置文件 /etc/selinux/config
SELINUX 设置为disabled

## YUM(更改阿里yum和EPEL源)
先用原有的源安装wget！不然你会后悔的
```sehll
yum install -y wget
```

备份原来的源信息文件（不然你也会后悔的）
```shell
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
```

下载阿里源文件
```sehll
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```

生成yum缓存（基操基操）
```sehll
yum clean all
yum makecache
```

添加EPEL源
yum -y install epel-release

备份epel-release 源
```sehll
mv epel.repo epel.repo.backup
```

下载阿里开源镜像的epel源文件

wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

再次清除系统yum缓存，并重新生成新的yum缓存
```shell
yum clean all
yum makecache
```

查看系统可用的yum源和所有的yum源
```shell
yum repolist enabled
```

更新一波
```sehll
yum update
```

## 升级内核版本，centos默认内核比较旧（可选)
导入内核仓源 (启用 ELRepo 仓库)
```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
```
查看最新版本(主线ml、长期支持lt)
```shell
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
```
安装最新的lt版本
```shell
yum --enablerepo=elrepo-kernel install kernel-lt
```
重新创建内核配置
```shell
grub2-mkconfig -o /boot/grub2/grub.cfg
```
查看当前开机默认选中内核
```shell
grub2-editenv list
# 如果非预期，该之 (启动内核列表从0开始排序)
grub2-set-default 0
```
查看已安装的所有内核包
```shell
rpm -qa | grep kernel
# 非必要的情况下 不必清理旧版内核包
```

## 安装mysql5.7
添加mysql rpm源
```shell
rpm -Uvh  http://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
```
安装
```shell
yum -y install mysql-community-server
```
[阿里云mysql手动配置文档](!https://help.aliyun.com/document_detail/116727.html)

创建非root用户、业务数据库、授权
```shell
mysql -uroot -p
CREATE USER 'xshop'@'%' IDENTIFIED BY 'my password';
CREATE DATABASE xshop;
# CREATE USER 'xshop'@'localhost' IDENTIFIED BY 'my password';
# CREATE USER 'xshop'@'ip' IDENTIFIED BY 'my password';
GRANT ALL ON xshop.* TO 'xshop'@'%';
```
设置默认编码为utf8 /etc/my.cn 添加
```shell
[mysqld]
character-set-server=utf8
[client]
default-character-set=utf8
[mysql]
default-character-set=utf8
```

## 常用的网络工具命令
### 根据端口查看socket连接情况(包括占用该端口的进程信息)
egrep 可以显示头部
```shell
sudo netstat -antp | egrep  "Proto|3306"
```
### 根据进程标识/PID信息查看占用的端口信息
```shell
sudo netstat -antp | egrep  "Proto|mysqld"
```

## linux 资源、文件描述符限制信息及设置
查看系统fd的使用情况(已分配、未分配、file-max)
```sehll
cat /proc/sys/fs/file-nr
```
查看并修改系统、单进程fd最大限制
```shell
# 系统级别
cat /proc/sys/fs/file-max
# 进程级别
cat /proc/sys/fs/nr_open
# 修改
vim /etc/sysctl.conf
# 文件末尾加
fs.file-max = 6553560
fs.nr_open = 2000000
# 使之生效
sysctl -p
```
查看并修改shell启动进程资源限制
```shell
# 查看
ulimit -n


# 修改(永久生效)

/etc/security/limits.conf

# nofile 文件描述符数
*    soft nofile 102400
*    hard nofile 102400
root soft nofile 102400
root hard nofile 102400

# nproc 最大进程/线程数
*    soft nproc unlimited
*    hard nproc unlimited
root soft nproc unlimited
root hard nproc unlimited


# 同时修改(适配守护进程) 

/etc/systemd/system.conf

DefaultLimitNOFILE=102400:102400
DefaultLimitNPROC=infinity:infinity

# 保存重启系统
```

单个进程能设置打开fd的最大值
```shell
cat /proc/sys/fs/nr_open
```

## 修改systemd unit service 配置(如ngix.service)
```sehll
// 开启启动
systemctl enable nginx
// 禁止开机启动
systemctl disable nginx
```

```shell
# 找到service的配置文件路径
systemctl status nginx
# 修改
vim /usr/lib/systemd/system/nginx.service
在 [Service] section 添加限制打开的fd数量配置
LimitNOFILE=102400:102400
# 重载配置
systemctl daemon-reload
# 修改nginx.conf
添加 worker_rlimit_nofile 16384
# 重启nginx
systemctl restart nginx
# 验证
/proc/<nginx-pid>/limits.
```

## nginx master-worker 模型
SO_RESUEPORT 端口复用

让多进程监听同一个端口，各个进程中accept socket fd不一样，有新连接建立时，内核只会唤醒一个进程来accept，并且保证唤醒的均衡性。

主进程（master 进程）首先通过 socket() 来创建一个 sock 文件描述符用来监听，然后fork生成子进程（workers 进程），子进程将继承父进程的 sockfd（socket 文件描述符），之后子进程 accept() 后将创建已连接描述符（connected descriptor）），然后通过已连接描述符来与客户端通信。


## docker 镜像地址
"https://reg-mirror.qiniu.com"

"https://docker.mirrors.ustc.edu.cn"

"https://dockerhub.azk8s.cn"

"https://hub-mirror.c.163.com"

"https://lrptals1.mirror.aliyuncs.com"

"https://registry.docker-cn.com"