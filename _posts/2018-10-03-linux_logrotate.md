---
layout: post
title: gunicorn 使用 linux logrotate 处理日志文件
category: linux 运维笔记
---
Normaly each process that opens the file gets its own `file table entry`, 
but only a single v-node table entry is required for a given file. 
> One reason each process gets its own file table entry is so that each process has its own `current offset` for the file.

gunicorn worker process 通过 os.fork 创建；他们共享同一个文件的 `file table entry(current offset)`；同时gunicorn 使用的 Python logging package is thread-safe.
所有 不管worker的类型是啥，它都能正确的处理多个worker下的日志了。

日志文件处理是运维经常要处理的事情，尽管现在语言本身自带的日志系统支持日志切割，但功能往往不能满足我们的需求；如 python 的 RotatingFileHandler。  

所以这里选择使用 liunx logrotate  

一切还得从一个使用 python flask 框架开发的 web app 说起。关于web app 的 wsgi 的选择我就不多讨论了，这里用的是 [gunicorn](http://docs.gunicorn.org/en/stable/)。

官网建议使用在 Debian GNU/Linux 平台上使用系统软件安装工具安装
```shell
$ sudo apt-get install gunicorn
```
这样的话就有不少的好处，其中之一就是利用 linux 自动日志处理工具 logrotate 自动处理日志文件。那如果使用 python 虚拟环境安装呢?  
当然还是可以用 logrotate 来处理的，不过需要手动写配置。ubuntu 配置文件路径:
```shell
/etc/logrotate.d/
```
切到该目录，新建一个文本文件 如 gunicorn 写入如下内容:
```shell
your_path_to_gunicorn_log_dir/*.log {
    su tr tr
    daily
    dateext
    missingok
    rotate 10
    compress
    delaycompress
    notifempty
    create 0640 tr tr
    sharedscripts
    postrotate
        killall -s USR1 gunicorn
    endscript
}
```
保存，好了，gunicorn 的所有日志文件每天会被自动分割，并且会预留最近10天的日志。