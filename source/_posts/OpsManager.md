---
title: OpsManager
date: 2018-05-11 06:49:09
tags:
---

# Docker构建OpsManage

要求具备一定docker基础： 构建步骤：

```
$ mkdir -p /data/opsmanage
$ cd /data/opsmanage
$ git clone https://github.com/welliamcao/OpsManage.git
$ cd OpsManage
```

```
$ vim start.sh
#!/bin/bash
echo_supervisord_conf > /etc/supervisord.conf
export PYTHONOPTIMIZE=1
cat > /etc/supervisord.conf << EOF
[unix_http_server]
file=/tmp/supervisor.sock   
[supervisord]
logfile=/tmp/supervisord.log 
logfile_maxbytes=50MB        
logfile_backups=10           
loglevel=info                
pidfile=/tmp/supervisord.pid 
nodaemon=false               
minfds=1024                  
minprocs=200                 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
[supervisorctl]
serverurl=unix:///tmp/supervisor.sock ; use a unix:// URL  for a unix socket
[program:celery-worker-default]
command=/usr/bin/python manage.py celery worker --loglevel=info -E -Q default
directory=/mnt/OpsManage
stdout_logfile=/var/log/celery-worker-default.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
numprocs=1
[program:celery-worker-ansible]
command=/usr/bin/python manage.py celery worker --loglevel=info -E -Q ansible 
directory=/mnt/OpsManage
stdout_logfile=/var/log/celery-worker-ansible.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
numprocs=1
[program:celery-beat]
command=/usr/bin/python manage.py celery beat
directory=/mnt/OpsManage
stdout_logfile=/var/log/celery-beat.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
numprocs=1
[program:celery-cam]
command=/usr/bin/python manage.py celerycam
directory=/mnt/OpsManage
stdout_logfile=/var/log/celery-celerycam.log
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
numprocs=1
EOF
/usr/bin/supervisord -c /etc/supervisord.conf
sleep 3
cd /mnt/OpsManage/
python /mnt/OpsManage/manage.py runserver 0.0.0.0:8000
```

```
$ vim superuser.json
[
    { "model": "auth.user",
        "pk": 1,
        "fields": {
            "username": "admin",
            "password": "pbkdf2_sha256$36000$eijqZp5ctxnE$xxCcAo/Rsuc+HddjGLQ6dUo/kDnuvayazUZ4V3xz52w=",
            "is_superuser": true,
            "is_staff": true,
            "is_active": true
        }
    }
]
```

```
$ cd ../
$ vim Dockerfile
FROM centos:latest
RUN yum install -y wget git zlib zlib-devel readline-devel sqlite-devel bzip2-devel openssl-devel gdbm-devel libdbi-devel ncurses-libs kernel-devel libxslt-devel libffi-devel python-devel mysql-devel zlib-devel sshpass libtool make
RUN cd /usr/local/src && wget --no-check-certificate https://github.com/pypa/pip/archive/1.5.5.tar.gz -O pip-1.5.5.tar.gz   && wget --no-check-certificate https://pypi.python.org/packages/f7/94/eee867605a99ac113c4108534ad7c292ed48bf1d06dfe7b63daa51e49987/setuptools-28.0.0.tar.gz#md5=9b23df90e1510c7353a5cf07873dcd22
RUN cd /usr/local/src && tar -xzvf setuptools-28.0.0.tar.gz && tar -xzvf pip-1.5.5.tar.gz && cd setuptools-28.0.0 && python setup.py install && cd ../pip-1.5.5 && python setup.py install && pip install -U pip && easy_install paramiko==2.4.1
RUN mkdir -p /etc/ansible/ && echo -ne "[defaults]\nlibrary = /usr/share/ansible/my_modules/\nhost_key_checking = False\n" > /etc/ansible/ansible.cfg && echo "welliam" | passwd --stdin root
ADD OpsManage /mnt/OpsManage/
RUN pip install -r /mnt/OpsManage/requirements.txt && cd /mnt/OpsManage/  && python manage.py makemigrations OpsManage && python manage.py makemigrations wiki && python manage.py migrate && python manage.py loaddata superuser.json
CMD  bash /mnt/OpsManage/start.sh
EXPOSE 8000
```

:wq 保存退出

2、修改OpsManage setting.py配置文件里面的MySQL与Redis设置

```
$ vim /data/opsmanage/OpsManage/OpsManage/settings.py
```

3、Docker build构建基础镜像：

```
$ docker build -t opsmanage:base .
```

注：第一次构建时间会很长，要注意等待或者是否出错

4、Docker run运行刚刚构建的镜像

```
$ docker run -d --name=opsmanage -v /data/opsmanage/OpsManage:/mnt/OpsManage -p 8000:8000 -p 2222:22 opsmanage:base
```

5、浏览器访问[http://ip:8000](http://ip:8000/) 默认账户密码是admin/admin