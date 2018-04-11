---
title: zabbiz使用之添加NGINX监控
date: 2018-04-11 12:45:47
tags: zabbix
---

# zabbix使用之添加NGINX监控

## Agent端

首先要检查Nginx是否安装了 `http_stub_status_module` 模块，通过下面的命令可以看到编译参数。

```bash
nginx -V
```

如果没有这个模块，还需要重新编译Nginx.

## 配置Nginx

Nginx 80端口的server配置增加如下的片段

  location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }

检查　http://xx.x.x.x/nginx_status/

```bash
>> curl http://127.0.0.1/nginx_status
Active connections: 4 
server accepts handled requests
 1162961 1162961 1210587 
Reading: 0 Writing: 1 Waiting: 3 
```

## zabbix-agent 配置

有3个步骤，首先是编写获取Nginx信息脚本，接着配置中增加key信息，然后重启agent 服务。

- 编写Nginx监控脚本，记住路径，后面配置需要用到。

！！注意脚本权限问题，agent运行用户要能执行。

```bash
>># mkdir -p /etc/zabbix-agent/scripts
>># cd /etc/zabbix-agent/scripts
>># vim nginx-check.sh
>># cat nginx-check.sh
```

```bash
#!/bin/bash
##################################
# Zabbix monitoring script
#
# nginx:
#  - anything available via nginx stub-status module
#
##################################
# Contact:
#  vincent.viallet@gmail.com
# Zabbix requested parameter
ZBX_REQ_DATA="$1"
ZBX_REQ_DATA_URL="$2"
# Nginx defaults
NGINX_STATUS_DEFAULT_URL="http://127.0.0.1/nginx_status"
WGET_BIN="/usr/bin/wget"
#
# Error handling:
#  - need to be displayable in Zabbix (avoid NOT_SUPPORTED)
#  - items need to be of type "float" (allow negative + float)
#
ERROR_NO_ACCESS_FILE="-0.9900"
ERROR_NO_ACCESS="-0.9901"
ERROR_WRONG_PARAM="-0.9902"
ERROR_DATA="-0.9903" # either can not connect / bad host / bad port
# Handle host and port if non-default
if [ ! -z "$ZBX_REQ_DATA_URL" ]; then
  URL="$ZBX_REQ_DATA_URL"
else
  URL="$NGINX_STATUS_DEFAULT_URL"
fi
# save the nginx stats in a variable for future parsing
NGINX_STATS=$($WGET_BIN -q $URL -O - 2> /dev/null)
# error during retrieve
if [ $? -ne 0 -o -z "$NGINX_STATS" ]; then
  echo $ERROR_DATA
  exit 1
fi
#
# Extract data from nginx stats
#
case $ZBX_REQ_DATA in
  active_connections)   echo "$NGINX_STATS" | head -1             | cut -f3 -d' ';;
  accepted_connections) echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f2 -d' ';;
  handled_connections)  echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f3 -d' ';;
  handled_requests)     echo "$NGINX_STATS" | grep -Ev '[a-zA-Z]' | cut -f4 -d' ';;
  reading)              echo "$NGINX_STATS" | tail -1             | cut -f2 -d' ';;
  writing)              echo "$NGINX_STATS" | tail -1             | cut -f4 -d' ';;
  waiting)              echo "$NGINX_STATS" | tail -1             | cut -f6 -d' ';;
  *) echo $ERROR_WRONG_PARAM; exit 1;;
esac
exit 0
```

- agent的配置文件 `/etc/zabbix/zabbix_agentd.conf` 中定义了其他key的包含目录 `Include=/etc/zabbix/zabbix_agentd.d/`, 如果没有这个配置请自己添加下。接着在 `/etc/zabbix/zabbix_agentd.d/` 目录新建一个文件 `nginx-params.conf`, 内容如下

  ```tex
  UserParameter=nginx[*],/usr/local/zabbix-agent/scripts/nginx-check.sh "$1" 
  ```

- 重启agent

  ```bash
  /etc/init.d/zabbix-agent restart
  ```

  ## Server 的Web端

  首先命令行测试下刚才agent好使不，确认好用之后在web端导入模板，之后就可以给对应主机添加监控喽。

  ```bash
  zabbix_get -s 127.0.0.1 -p 10050 -k "nginx[reading]"

  0123
  ```

  登录Zabbix3.0 的web界面，一次选择 `Configuration` > `Templates` ， 在主界面的右上角有个 `Import` 按钮，用来导入模板。

  模板文件比较长留一个[下载地址](https://github.com/jizhang/zabbix-templates/blob/master/nginx/nginx-template.xml)

  导入之后就可以给主机添加监控啦。