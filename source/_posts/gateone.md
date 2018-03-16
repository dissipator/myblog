---
title: gateone
date: 2018-03-13 22:32:23
tags: [ssh, gateone]
categories: 堡垒机
---
# 1. Gate One简介
GateOne是一款基于HTML5的开源终端模拟器/SSH客户端。它可以用于运行任何终端应用。用户可以将GateOne嵌入其他应用程序从而提供各类终端访问界面，它也支持各类基于Web的管理界面。 

Gate One在后台进程是使用Python实现的，其前端则是JaveScript+WebSockets。关于Gate One的介绍、源码和文档请参考下面的链接。

Gate One主页：http://liftoffsoftware.com/Products/GateOne
Gate One源码：https://github.com/liftoff/GateOne
Gate One文档：http://liftoff.github.io/GateOne/

# 2. Gate One安装
Gate One要求系统必须满足下面两个前提条件，

  （1）python: 2.6+ or 3.2+
  （2）Tornado Framework 2.2+

## 2.1系统环境准备
在命令行终端中输入命令
	$ python -V
查看你本机是否安装了python，如果先安装python（注：树莓派上面自己带有python2和python3，python2对应python命令，python3对应python3命令）。

然后安装pip，

	$ wget  --no-check-certificate https://bootstrap.pypa.io/get-pip.py
	$ sudo python get-pip.py
安装tornado，

	$ sudo pip install tornado
安装完成之后，我们来验证一下我们的环境，

	$ python -V
	$ python -c "import tornado; print(tornado.version)"

## 2.2 Gate One获取和安装
如果本地没有安装git，则先安装git，

	$ sudo apt-get install git
获取Gate One源码并进行安装，（注：这个地方git clone会下载到当前目录下！所以下载前记得cd到你想下载的位置目录去）

	$ git clone https://github.com/liftoff/GateOne.git
	$ cd GateOne
	$ sudo python ./setup.py install
# 3. Gate One验证
Gate One的配置文件是/etc/gateone/conf.d/10server.conf，


	sudo vi /etc/gateone/conf.d/10server.conf  

我们修改配置文件如下图：



这里我们修改了：
"address" = "192.168.1.2" 这个是树莓派的ip地址
"https_redirect" = "true"
"port" = 8000 这个是监听端口

其他默认就可以了
输入命令：
	$ sudo gateone
 

启动后，通过打印的信息，我们看到Gate One服务监听了8000端口号，然后在浏览器中输入https://192.168.1.106:8000/即可打开gateone的网页
网络会进行拦截，点击   高级 ——添加例外——确认即可
然后点击中间的Terminal图标登陆某台机器，
到此链接成功，可以web浏览器远程终端操作树莓派了（这个地方我修改了端口号：8008，因为前面多次操作，出现下面遇到的问题！）
多次链接可能会出现这种情况：
红色错误显示不能监听，端口被占用了，可以修改签名配置文件端口号。重新测试。

# 4. 配置auth pam

安装libpam_pwdfile包

	sudo apt install libpam_pwdfile

	vi /etc/gateone/conf.d/20authentication.conf
	auth = "pam"
	pam_realm = "AccessGateway1"
	pam_service = "gateone"
 

在Safari下无法使用，报错如下：
The WebSocket connection was closed. Will attempt to reconnect every 5 seconds...
NOTE: Some web proxies do not work properly with WebSockets.
 
PC和Android中的Chrome正常。
 
	vi /etc/pam.d/gateone
	#%PAM-1.0
	# Login using a htpasswd file
	#@include common-sessionauth
	required pam_pwdfile.so   pwdfile=/etc/gateone/passwd
	required pam_permit.so
	 
	auth = "pam"
	pam_realm = "AccessGateway1"
	pam_service = "gateone"
 
 
密码生成用在线工具就行，记得选择Crypt方式：http://tool.oschina.net/htpasswd
将生成的信息加入密码文件就行。

	 sudo htpasswd -c -d /etc/gateone/users.passwd user1



