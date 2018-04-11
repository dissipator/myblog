---
title: zabbiz使用之添加Mysql监控
date: 2018-04-11 10:27:06
tags: zabbix
---

# 添加 Mysql 监控

Agent 端配置：
在/etc/zabbix/zabbix_agentd.d/userparameter_mysql.conf 文件中指定了 zabbix agent
如何获取 mysql 服务的各种登录信息，并在/var/lib/zabbix/目录中新建”.my.cnf”文件，用
以指定 zabbix agent 如何登陆数据库，默认使用的是 zabbix 用户，可以在 zabbix_conf
文件中找到密码。

```bash
#mkdir /var/lib/zabbix
#vim /var/lib/zabbix/.my.cnf
[mysql]
host=localhost
user=zabbix
password=zabbix
socket=/var/lib/mysql/mysql.sock
[mysqladmin]
host=localhost
user=zabbix
password=zabbix
socket=/var/lib/mysql/mysql.sock
#service zabbix-agent restart
#在数据库中进行授权：
Mysql> GRANT USAGE ON *.* TO zabbix@localhost IDENTIFIED BY ‘zabbix’;
Mysql>FLUSH PRIVILEGES;
```

在 zabbix_server 端测试是否可以得到检测数据：
zabbix_get -s 10.10.1.13 -p 10050 -k mysql.ping
1
如显示 1，则代表可以通过zabbix_agent 获取到数据。
Web 端配置：
依次点击 组态--主机--（要监控 mysql 的主机）--模板--选择--Template App Mysql--添加
--更新。
完成后，点击监测中图形，选择主机和 Mysql bandwidth，等待检测。