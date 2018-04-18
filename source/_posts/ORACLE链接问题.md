---
title: ORACLE链接问题
date: 2018-04-18 06:43:07
tags:

---

#  ORACLE链接问题

## 找不到动态库

ldd sqlplus
echo $LD_LIBRARY_PATH
export $LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

## ORA-21561: OID generation failed

修改/etc/hosts文件，追加本机map，否则会报""错误

\#vi /etc/hosts

追加如下信息：

192.168.1.171 centos62

其中centos62为本机主机名，可以通过hostname命令查看