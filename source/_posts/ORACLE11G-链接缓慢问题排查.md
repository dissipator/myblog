---
title: ORACLE11G 链接缓慢问题排查
date: 2018-04-08 12:55:55
tags: linux,ORACLE
---

# 问题描述：

1. 服务器centos7,客服端任意
2. 本地使用sqlplus / 连接很快，sqlplus xxx/xxx@127.0.0.1/sid 很慢
3. windows客服端在创建链接后也很慢

# 问题排查

1. tnsping  没有延迟
2. 11G用户验证问题（只要有登陆错误，就会有延迟累计）－－－－－－不是
3. 监听文件配置问题　－－－－－－不是
4. 日志文件过大　－－－－－－－不是
5. 机器名在监听文件和网络上的名字不一致－－－－－－－是
   1. /etc/hosts
   2. /etc/hostname
   3. $ORACLE_HOME/network/admin/tnsname.ora
   4. /etc/sysconf/network

      ​