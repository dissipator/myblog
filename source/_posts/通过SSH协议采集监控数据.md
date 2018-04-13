---
title: 通过SSH协议采集监控数据
date: 2018-04-12 07:51:07
tags: zabbix
---

# 通过SSH协议采集监控数据

Zabbix中通过SSH协议也可以实现监控目标，通过SSH agent监控方式，需要对服务器进行监控但又不能安装Zabbix agent的环境中非常有用。Zabbix中使用SSh agent时要求libssh2的最低版本是 1.0.0。

SSH agent支持两种身份认证的方式：基于用户名密码的方式和基于秘钥的方式，使用用户名密码的方式不需要任何特殊的配置，添加监控项时需要在页面中输入明文的用户名和密码，因此在实际环境中建议使用基于秘钥的方式，但这个方式需要做些额外的配置。下面我们来看看基于秘钥的方式如何配置的。

## 首先，检查zabbix用户的设置，使用下面的命令。

**# grep zabbix /etc/passwd**

zabbix:x:996:994:Zabbix Monitoring System:/var/lib/zabbix:/sbin/nologin

​     可以看到系统中zabbix用户的home目录是/var/lib/zabbix，确认该目录是否存在，如果不存在，使用下面的命令创建目录。

​     **# mkdir –p /var/lib/zabbix/.ssh**

​     **# chown –R zabbix:zabbix /var/lib/zabbix**

接下来我们需要修改zabbix-server.conf文件，配置SSH Key文件的存储路径。

>vi /etc/zabbix/zabbix-server.conf
SSHKeyLocation=/ var/lib/zabbix/.ssh
修改完zabbix-server.conf配置文件后重启Zabbixserver。
```
systemctl restart zabbix-server
```
现在，我们生成zabbix用户的SSH Key，询问passphrase时直接回车就可以。

> sudo -u zabbixssh-keygen -t rsa -b 2048

Generating public/private rsa key pair.

Enter file in which to save the key (/var/lib/zabbix/.ssh/id_rsa):

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Your identification has been saved in /var/lib/zabbix/.ssh/id_rsa.

Your public key has been saved in /var/lib/zabbix/.ssh/id_rsa.pub.

The key fingerprint is:

15:3e:d5:61:ed:16:b3:0a:67:9d:35:f0:35:55:0b:7e zabbix@zbxserver

The key‘s randomart image is:

+--[ RSA 2048]- -----+

|          . .+++*|

|          . o..++*|

|          +  ..EB|

|          . o o.+o|

|         S   + .. |

|             .   |

|                 |

|                 |

|                 |

+----------------------------+

\# ll

total 8

-rw------- 1 zabbix zabbix 1675 May 31 13:29 id_rsa

-rw-r--r-- 1 zabbix zabbix 398 May 31 13:29 id_rsa.pub

接下来拷贝秘钥文件到被监控主机中，假设被监控主机的IP 地址是192.168.10.112。

**# sudo -u zabbixssh-copy-id root@192.168.10.112**

The authenticity of host ‘192.168.10.112 (192.168.10.112)‘ can‘t beestablished.

ECDSA key fingerprint is0d:33:e5:5c:43:c3:5b:c4:da:e4:f0:6d:0c:fb:4a:6e.

Are you sure you want to continue connecting (yes/no)? yes

/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), tofilter out any that are already installed

/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if youare prompted now it is to install the new keys

root@192.168.10.112‘s password:

 

Number of key(s) added: 1

 

Now try logging into the machine, with:   "ssh ‘root@192.168.10.112‘"

and check to make sure that only the key(s) you wanted were added.

现在我们测试一下能否登录成功。

**# sudo -u zabbix ssh root@192.168.10.112**

当完成上面的配置后，就可以创建SSH agent监控方式的监控项了。

配置SSH agent监控项的步骤：

1、  创建一个新主机（Configuration --> Host --> Create host）。在主机配置页面的Host标签下添加Agentinterfaces接口配置，如下图3-14所示。

[![技术分享](https://s3.51cto.com/wyfs02/M01/94/43/wKiom1kL7o6CJbSGAAA8oE4ynjA504.jpg)](https://s3.51cto.com/wyfs02/M01/94/43/wKiom1kL7o6CJbSGAAA8oE4ynjA504.jpg)

图 3-14

2、  在主机中创建新的监控项。

- Name中输入监控项名称，例如Check uname。
- Type中选择SSH agent。
- Key中内容替换成ssh.run[uname]。
- Host interface 中选择agent接口。
- Authentication method中选择Public key。
- User name中填写root ，Public key file中填写id_rsa_pub，Private keyfile中填写 id_rsa。
- Key passphrase留空，如果生成密钥时你输入了passphrase，就需要在这里输入相同的passphrase。
- Executed script中输入uname -a。
- Type of information中选择Text类型。
- 其他参数可以保持不变，点击Add按钮保存。

如下图3—15所示。

[![技术分享](https://s2.51cto.com/wyfs02/M00/94/44/wKiom1kL7p3hNFe5AAEg9a88qcQ702.jpg)](https://s2.51cto.com/wyfs02/M00/94/44/wKiom1kL7p3hNFe5AAEg9a88qcQ702.jpg)

图 3-15

3、  Monitoring --> Latest data页面查看监控项。

使用SSH agent监控方式需要注意的是libssh2可能会把可执行脚本的输出截断到32KB，另外在脚本中最好使用命令的全路径。