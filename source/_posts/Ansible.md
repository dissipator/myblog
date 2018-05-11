---
title: Ansible
date: 2018-04-18 03:00:54
tags:
---

# ansible使用记录

### **Ansible 安装教程**

ansible 的安装轻而易举，许多发行版的第三方软件仓库中都有现成的软件包，可以直接安装。其他简单的安装方法包括使用 pip 安装它，或者从 github 里获取最新的版本。若想使用你的软件包管理器安装，在[基于 RHEL/CentOS Linux 的系统里你很可能需要 EPEL 仓库](http://www.cyberciti.biz/faq/fedora-sl-centos-redhat6-enable-epel-repo/)。

#### 在基于 RHEL/CentOS Linux 的系统中安装 ansible

输入如下 [yum 命令](http://www.cyberciti.biz/faq/rhel-centos-fedora-linux-yum-command-howto/):

```
$ sudo yum install ansible
```

#### 在基于 Debian/Ubuntu Linux 的系统中安装 ansible

输入如下 [apt-get 命令](http://www.cyberciti.biz/tips/linux-debian-package-management-cheat-sheet.html):

```
$ sudo apt-get install software-properties-common$ sudo apt-add-repository ppa:ansible/ansible$ sudo apt-get update$ sudo apt-get install ansible
```

#### 使用 pip 安装 ansible

[pip 命令是一个安装和管理 Python 软件包的工具](http://www.cyberciti.biz/faq/debian-ubuntu-centos-rhel-linux-install-pipclient/)，比如它能管理 Python Package Index 中的那些软件包。如下方式在 Linux 和类 Unix 系统中通用：

```
$ sudo pip install ansible
```

#### 从源代码安装最新版本的 ansible

你可以通过如下命令从 github 中安装最新版本：

```
$ cd ~$ git clone git://github.com/ansible/ansible.git$ cd ./ansible$ source ./hacking/env-setup
```

当你从一个 git checkout 中运行 ansible 的时候，请记住你每次用它之前都需要设置你的环境，或者你可以把这个设置过程加入你的 bash rc 文件中：

```
# 加入 BASH RC$ echo "export ANSIBLE_HOSTS=~/ansible_hosts" >> ~/.bashrc$ echo "source ~/ansible/hacking/env-setup" >> ~/.bashrc
```

ansible 的 hosts 文件包括了一系列它能操作的主机。默认情况下 ansible 通过路径 /etc/ansible/hosts 查找 hosts 文件，不过这个行为也是可以更改的，这样当你想操作不止一个 ansible 或者针对不同的数据中心的不同客户操作的时候也是很方便的。你可以通过命令行参数 -i 指定 hosts 文件：

```
$ ansible all -m shell -a "hostname" --ask-pass -i /etc/some/other/dir/ansible_hosts
```

不过我更倾向于使用一个环境变量，这可以在你想要通过 source 一个不同的文件来切换工作目标的时候起到作用。这里的环境变量是 $ANSIBLE_HOSTS，可以这样设置：

```
$ export ANSIBLE_HOSTS=~/ansible_hosts
```

一旦所有需要的组件都已经安装完毕，而且你也准备好了你的 hosts 文件，你就可以来试一试它了。为了快速测试，这里我把 127.0.0.1 写到了 ansible 的 hosts 文件里：

```
$ echo "127.0.0.1" > ~/ansible_hosts
```

现在来测试一个简单的 ping：

```
$ ansible all -m ping
```

或者提示 ssh 密码：

```
$ ansible all -m ping --ask-pass
```

我在刚开始的设置中遇到过几次问题，因此这里强烈推荐为 ansible 设置 SSH 公钥认证。不过在刚刚的测试中我们使用了 --ask-pass，在一些机器上你会需要[安装 sshpass](http://www.cyberciti.biz/faq/noninteractive-shell-script-ssh-password-provider/) 或者像这样指定 -c paramiko：

```
$ ansible all -m ping --ask-pass -c paramiko
```

当然你也可以[安装 sshpass](http://www.cyberciti.biz/faq/noninteractive-shell-script-ssh-password-provider/)，然而 sshpass 并不总是在标准的仓库中提供，因此 paramiko 可能更为简单。

### 设置 SSH 公钥认证

于是我们有了一份配置，以及一些基础的其他东西。现在让我们来做一些实用的事情。ansible 的强大很大程度上体现在 playbooks 上，后者基本上就是一些写好的 ansible 脚本（大部分来说），不过在制作一个 playbook 之前，我们将先从一些一句话脚本开始。现在让我们创建和配置 SSH 公钥认证，以便省去 -c 和 --ask-pass 选项：

```
$ ssh-keygen -t rsa
```

现在显然有很多种方式来把它放到远程主机上应该的位置。不过既然我们正在使用 ansible，就用它来完成这个操作吧：

```
$ ansible all -m copy -a "src=/home/xxx/.ssh/id_rsa.pub dest=/tmp/id_rsa.pub" --ask-pass -c paramiko
```

下一步，把公钥文件添加到远程服务器里。输入：

```
$ ansible all -m shell -a "cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys" --ask-pass -c paramiko
```

样例输出：

```
SSH password:127.0.0.1 | FAILED | rc=1 >>/bin/sh: /root/.ssh/authorized_keys: Permission denied
```

矮油，我们需要用 root 来执行这个命令，所以还是加上一个 -u 参数吧：

```
$ ansible all -m shell -a "cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys" --ask-pass -c paramiko -u root
```

样例输出：

```
SSH password:127.0.0.1 | success | rc=0 >>
```

请注意，我刚才这是想要演示通过 ansible 来传输文件的操作。事实上 ansible 有一个更加方便的内置 SSH 密钥管理支持：

```
$ ansible all -m authorized_key -a "user=xxx key='{{ lookup('file', '/home/xxx/.ssh/id_rsa.pub') }}' path=/home/xxx/.ssh/authorized_keys manage_dir=no" --ask-pass -c paramiko
```

现在这些密钥已经设置好了。我们来试着随便跑一个命令，比如 hostname，希望我们不会被提示要输入密码

```
$ ansible all -m shell -a "hostname" -u root
```

样例输出：

```
127.0.0.1 | success | rc=0 >>
```

成功！！！现在我们可以用 root 来执行命令，并且不会被输入密码的提示干扰了。我们现在可以轻易地配置任何在 ansible hosts 文件中的主机了。让我们把 /tmp 中的公钥文件删除：

```
$ ansible all -m file -a "dest=/tmp/id_rsa.pub state=absent" -u root
```

样例输出：

```
127.0.0.1 | success >> {    "changed": true,    "path": "/tmp/id_rsa.pub",    "state": "absent"}
```

下面我们来做一些更复杂的事情，我要确定一些软件包已经安装了，并且已经是最新的版本：

```
$ ansible all -m zypper -a "name=apache2 state=latest" -u root
```

样例输出：

```
127.0.0.1 | success >> {    "changed": false,    "name": "apache2",    "state": "latest"}
```

很好，我们刚才放在 /tmp 中的公钥文件已经消失了，而且我们已经安装好了最新版的 apache。下面我们来看看前面命令中的 -m zypper，一个让 ansible 非常灵活，并且给了 playbooks 更多能力的功能。如果你不使用 openSuse 或者 Suse enterprise 你可能还不熟悉 zypper, 它基本上就是 suse 世界中相当于 yum 的存在。在上面所有的例子中，我的 hosts 文件中都只有一台机器。除了最后一个命令外，其他所有命令都应该在任何标准的 *nix 系统和标准的 ssh 配置中使用，这造成了一个问题。如果我们想要同时管理多种不同的机器呢？这便是 playbooks 和 ansible 的可配置性闪闪发光的地方了。首先我们来少许修改一下我们的 hosts 文件：

```
$ cat ~/ansible_hosts
```

样例输出：

```
[RHELBased]121.12.12.12
[SUSEBased]127.0.0.1
```

首先，我们创建了一些分组的服务器，并且给了他们一些有意义的标签。然后我们来创建一个为不同类型的服务器执行不同操作的 playbook。你可能已经发现这个 yaml 的数据结构和我们之前运行的命令行语句中的相似性了。简单来说，-m 是一个模块，而 -a 用来提供模块参数。在 YAML 表示中你可以先指定模块，然后插入一个冒号 :，最后指定参数。

```
---
- hosts: SUSEBased  
remote_user: root  
tasks:    
- zypper: 
name=apache2 
state=latest
- hosts: RHELBased  
remote_user: root  
tasks:    
- yum: 
name=httpd 
state=latest
```

现在我们有一个简单的 playbook 了，我们可以这样运行它：

```
$ ansible-playbook testPlaybook.yaml -f 10
```

注意，你会看到 ansible 联系到的每一台机器的输出。-f 参数让 ansible 在多台主机上同时运行指令。除了指定全部主机，或者一个主机分组的名字以外，你还可以把导入 ssh 公钥的操作从命令行里转移到 playbook 中，这将在设置新主机的时候提供很大的方便，甚至让新主机直接可以运行一个 playbook。为了演示，我们把我们之前的公钥例子放进一个 playbook 里：

```
---
- hosts: SUSEBased  
remote_user: xxx  
sudo: yes  
tasks:    
- authorized_key: 
user=root 
key="{{ lookup('file', '/home/xxx/.ssh/id_rsa.pub') }}" path=/root/.ssh/authorized_keys 
manage_dir=no
- hosts: RHELBased
remote_user: aaa  
sudo: yes  
tasks:    
- authorized_key: 
user=root 
key="{{ lookup('file', '/home/xxx/.ssh/id_rsa.pub') }}" path=/root/.ssh/authorized_keys 
manage_dir=no
```

除此之外还有很多可以做的事情，比如在启动的时候把公钥配置好，或者引入其他的流程来让你按需配置一些机器。不过只要 SSH 被配置成接受密码登陆，这些几乎可以用在所有的流程中。在你准备开始写太多 playbook 之前，另一个值得考虑的事情是，代码管理可以有效节省你的时间。机器需要不断变化，然而你并不需要在每次机器发生变化时都重新写一个 playbook，只需要更新相关的部分并提交这些修改。与此相关的另一个好处是，如同我之前所述，你可以从不同的地方管理你的整个基础结构。你只需要将你的 playbook 仓库 git clone 到新的机器上，就完成了管理所有东西的全部设置流程。



### 现实中的 ansible 例子

我知道很多用户经常使用 pastebin 这样的服务，以及很多公司基于显而易见的理由配置了他们内部使用的类似东西。最近，我遇到了一个叫做 showterm 的程序，巧合之下我被一个客户要求配置它用于内部使用。这里我不打算赘述这个应用程序的细节，不过如果你感兴趣的话，你可以使用 Google 搜索 showterm。作为一个合理的现实中的例子，我将会试图配置一个 showterm 服务器，并且配置使用它所需要的客户端应用程序。在这个过程中我们还需要一个数据库服务器。现在我们从配置客户端开始：

```
---
- hosts: showtermClients  
remote_user: root  
tasks:    
- yum: 
name=rubygems 
state=latest    
- yum: 
name=ruby-devel 
state=latest    
- yum: 
name=gcc 
state=latest    
- gem: 
name=showterm 
state=latest 
user_install=no
```

这部分很简单。下面是主服务器：

```
---
- hosts: showtermServers  
remote_user: root  
tasks:    
- 
name: 
ensure packages are installed      
yum: 
name={{item}} 
state=latest      
with_items:        
- postgresql        
- postgresql-server        
- postgresql-devel        
- python-psycopg2        
- git        
- ruby21        
- ruby21-passenger   
- name: 
showterm server from github      
git: 
repo=https://github.com/ConradIrwin/showterm.io dest=/root/showterm
- name: 
Initdb      
command: service postgresql initdb               creates=/var/lib/pgsql/data/postgresql.conf     
- name: 
Start PostgreSQL and enable at boot      
service: 
name=postgresql               
enabled=yes               
state=started    
- gem: 
name=pg 
state=latest 
user_install=no  
handlers:   
- name: restart postgresql     
service: 
name=postgresql 
state=restarted 
- hosts: showtermServers  
remote_user: root  
sudo: yes  
sudo_user: postgres  
vars:    
dbname: showterm    
dbuser: showterm    
dbpassword: showtermpassword  
tasks:    
- name: create db      
postgresql_db: 
name={{dbname}}     
- name: create user with ALL priv      
postgresql_user: 
db={{dbname}} 
name={{dbuser}} 
password={{dbpassword}} 
priv=ALL
- hosts: showtermServers  
remote_user: root  
tasks:    
- name: database.yml      
template: 
src=database.yml 
dest=/root/showterm/config/database.yml
- hosts: showtermServers  
remote_user: root  
tasks:    
- name: run bundle install      
shell: bundle install      
args:        
chdir: /root/showterm
- hosts: showtermServers  
remote_user: root  
tasks:    
- name: run rake db tasks      
shell: 'bundle exec rake db:create db:migrate db:seed'      args:
chdir: /root/showterm
- hosts: showtermServers  
remote_user: root  
tasks:    
- name: apache config      
template: 
src=showterm.conf 
dest=/etc/httpd/conf.d/showterm.conf
```

还凑合。请注意，从某种意义上来说这是一个任意选择的程序，然而我们现在已经可以持续地在任意数量的机器上部署它了，这便是配置管理的好处。此外，在大多数情况下这里的定义语法几乎是不言而喻的，wiki 页面也就不需要加入太多细节了。当然在我的观点里，一个有太多细节的 wiki 页面绝不会是一件坏事。

### 扩展配置

我们并没有涉及到这里所有的细节。Ansible 有许多选项可以用来配置你的系统。你可以在你的 hosts 文件中内嵌变量，而 ansible 将会把它们应用到远程节点。如：

```
[RHELBased]
9.9.9.9.  http_port=443 
8.8.8.8   http_port=80  ansible_ssh_user=mdonlon 
[SUSEBased]
127.0.0.1  http_port=443
```

尽管这对于快速配置来说已经非常方便，你还可以将变量分成存放在 yaml 格式的多个文件中。在你的 hosts 文件路径里，你可以创建两个子目录 group*vars 和 host*vars。在这些路径里放置的任何文件，只要能对得上一个主机分组的名字，或者你的 hosts 文件中的一个主机名，它们都会在运行时被插入进来。所以前面的一个例子将会变成这样：

```
ultrabook:/etc/ansible # pwd
/etc/ansible
ultrabook:/etc/ansible # tree.
├── group_vars
│   ├── RHELBased
│   └── SUSEBased
├── hosts
└── host_vars
    ├── 10.50.1.33
    └── 10.50.1.47
```

------

```
2 directories, 5 files
ultrabook:/etc/ansible # cat hosts
[RHELBased]
10.50.1.33
10.50.1.47
[SUSEBased]
127.0.0.1
ultrabook:/etc/ansible # cat group_vars/RHELBased
ultrabook:/etc/ansible # cat group_vars/SUSEBased
---
http_port: 443
ultrabook:/etc/ansible # cat host_vars/10.50.1.33
---
http_port: 443
ultrabook:/etc/ansible # cat host_vars/10.50.1.47
---
http_port:80
ansible_ssh_user: mdonlon
```

### 改善 Playbooks

组织 playbooks 也已经有很多种现成的方式。在前面的例子中我们用了一个单独的文件，因此这方面被大幅地简化了。组织这些文件的一个常用方式是创建角色。简单来说，你将一个主文件加载为你的 playbook，而它将会从其它文件中导入所有的数据，这些其他的文件便是角色。举例来说，如果你有了一个 wordpress 网站，你需要一个 web 前端，和一个数据库。web 前端将包括一个 web 服务器，应用程序代码，以及任何需要的模块。数据库有时候运行在同一台主机上，有时候运行在远程的主机上，这时候角色就可以派上用场了。你创建一个目录，并对每个角色创建对应的小 playbook。在这个例子中我们需要一个 apache 角色，mysql 角色，wordpress 角色，mod_php，以及 php 角色。最大的好处是，并不是每个角色都必须被应用到同一台机器上。在这个例子中，mysql 可以被应用到一台单独的机器。这同样为代码重用提供了可能，比如你的 apache 角色还可以被用在 python 和其他相似的 php 应用程序中。展示这些已经有些超出了本文的范畴，而且做一件事总是有很多不同的方式，我建议搜索一些 ansible 的 playbook 例子。有很多人在 github 上贡献代码，当然还有其他一些网站。


## ansible命令集：

/usr/bin/ansible: # Ansibe AD-Hoc 临时命令执行工具，常用于临时命令的执行
/usr/bin/ansible-doc: # Ansible 模块功能查看工具
/usr/bin/ansible-galaxy: # 下载/上传优秀代码或Roles模块的官网平台，基于网络的
/usr/bin/ansible-playbook: # Ansible 定制自动化的任务集编排工具
/usr/bin/ansible-pull: # Ansible远程执行命令的工具（使用较少，海量机器时使用，对运维的架构能力要求较高）
/usr/bin/ansible-vault: # Ansible 文件加密工具
/usr/bin/ansible-console: # Ansible基于Linux Consoble界面可与用户交互的命令执行工具
/usr/share/ansible_plugins:Ansible高级自定义插件目录（需要python基础）
/etc/ansible/ansible.cfg:配置文件
/etc/ansible/hosts:主机清单

## Ansible 配置文件

　　绝大多数配置保持默认就好
1）[defaults]　　
```txt 
#inventory      = /etc/ansible/hosts  # 主机列表配置文件
#library       = /usr/share/my_modules/ # 库文件存放目录 
#remote_tmp     = $HOME/.ansible/tmp  # 生成的临时py命令文件存放在远程主机的目录
#local_tmp      = $HOME/.ansible/tmp # 本机的临时命令执行目录
#forks          = 5   # 默认并发数
#poll_interval  = 15   # 默认的线程池
#sudo_user      = root  # 默认sudo 用户
#ask_sudo_pass = True
#ask_pass      = True
#transport      = smart
#remote_port    = 22
#module_lang    = C
#module_set_locale = False

host_key_checking = False  ### 检查对应服务器的host_key
```
（2）[privilege_escalation]
（3）[paramiko_connection]
（4）[ssh_connection]
（5）[accelerate]
（6）[selinux]
（7）[colors]

## Ansible命令使用说明
### ansible 
```shell
#调用ping模块检测node3主机是否存活（node2,3,4能基于主机名通信，且已做过免密钥通信）　　
[root@node2 ~/.ssh]# ansible node3 -m ping 
node3 | success >> {
　　"changed": false, 
　　"ping": "pong"　　
}
[root@node2 ~/.ssh]# 
root@node2 ~/.ssh]# ansible -h　　
Usage: ansible <host-pattern> [options]
Options:
　　-a MODULE_ARGS, --args=MODULE_ARGS    #模块的参数,如果执行默认COMMAND的模块，即是命令参数,如：“date”,"pwd"等等
　　module arguments    #模块参数
　　--ask-become-pass     ask for privilege escalation password # Ansible su切换用户的时候使用该参数输入密码
　　-k, --ask-pass        ask for SSH password  #登录密码，提示输入SSH密码而不是假设基于密钥的验证
　　--ask-su-pass         ask for su password    #su切换密码
　　-K, --ask-sudo-pass   ask for sudo password  #提示密码使用sudo,sudo表示提权操作
　　--ask-vault-pass      ask for vault password  # ansible-valut 加密文件
　　-B SECONDS, --background=SECONDS     #后台运行超时时间
　　run asynchronously, failing after X seconds
　　(default=N/A)
　　-C, --check           don't make any changes; instead, try to predict some    #只是测试一下会改变什么内容，不会真正去执行;相反,试图预测一些可能发生的变化
　　of the changes that may occur
　　-c CONNECTION, --connection=CONNECTION   连接类型使用。可能的选项是paramiko(SSH),SSH和地方。当地主要是用于crontab或启动。
　　connection type to use (default=smart)
　　-e EXTRA_VARS, --extra-vars=EXTRA_VARS  # 调用外部变量
　　-f FORKS, --forks=FORKS    # Ansible一次命令执行并发的线程数,默认是5
　　specify number of parallel processes to use
　　(default=5)
　　-h, --help            show this help message and exit   #打开帮助文档API
　　-i INVENTORY, --inventory-file=INVENTORY    #指定库存主机文件的路径,默认为/etc/ansible/hosts
　　specify inventory host file
　　(default=/etc/ansible/hosts)
　　-l SUBSET, --limit=SUBSET    #进一步限制所选主机/组模式  --limit=192.168.91.135 只对这个ip执行
　　further limit selected hosts to an additional pattern
　　--list-hosts          outputs a list of matching hosts; does not execute
　　anything else
　　-m MODULE_NAME, --module-name=MODULE_NAME   #执行模块的名字，默认使用 command 模块，所以如果是只执行单一命令可以不用 -m参数
　　module name to execute (default=command)
　　-M MODULE_PATH, --module-path=MODULE_PATH    #要执行的模块的路径，默认为/usr/share/ansible/
　　specify path(s) to module library
　　(default=/usr/share/ansible/)
　　-o, --one-line        condense output      #压缩输出，摘要输出.尝试一切都在一行上输出。
　　-P POLL_INTERVAL, --poll=POLL_INTERVAL    #调查背景工作每隔数秒。需要- b
　　set the poll interval if using -B (default=15)
　　--private-key=PRIVATE_KEY_FILE    #私钥路径，使用这个文件来验证连接
　　use this file to authenticate the connection
　　-S, --su              run operations with su    用 su 命令
　　-R SU_USER, --su-user=SU_USER      #指定SU的用户，默认是root用户
　　run operations with su as this user (default=root)
　　-s, --sudo            run operations with sudo (nopasswd)    
　　-U SUDO_USER, --sudo-user=SUDO_USER    #sudo到哪个用户，默认为 root  
　　desired sudo user (default=root)
　　-T TIMEOUT, --timeout=TIMEOUT    #指定SSH默认超时时间，  默认是10S
　　override the SSH timeout in seconds (default=10)
　　-t TREE, --tree=TREE  log output to this directory    #将日志内容保存在该输出目录,结果保存在一个文件中在每台主机上。
　　-u REMOTE_USER, --user=REMOTE_USER    #远程用户， 默认是root用户
　　connect as this user (default=root)
　　--vault-password-file=VAULT_PASSWORD_FILE  
　　vault password file
　　-v, --verbose         verbose mode (-vvv for more, -vvvv to enable    详细信息
　　connection debugging)
　　--version             show program's version number and exit   #输出ansible的版本
```

#### Ansiblie命令执行过程 （-vvvv）

加载自己的配置文件 默认/etc/ansible/ansible.cfg
加载自己对应的模块文件，如command
通过ansible将模块或命令生成对应的临时py文件，并将该 文件传输至远程服务器的
　　对应执行用户的家目录的.ansible/tmp/XXX/XXX.PY文件
给文件+x执行
执行并返回结果
删除临时py文件，sleep 0退出
#### ansible主机清单的配置
　　/ect/ansible/hosts,定义方式：
>直接指明主机地址或主机名
>node3　　
>172.16.47.104
>定义一个主机组，把主机地址或主机名写进去，然后通过组名来调用这个组
>[webservers]　　
>node3
>node4
>如果没有使用公钥，想要使用密码，也可以这样写（适用于第一次登陆控制）
>格式：【主机名】 【主机地址】 【主机密码】  默认是root用户来进行的　　
>　　[keepalived]
>　　keepalived1  ansible_ssh_host=192.168.146.136 ansible_ssh_pass="test"
>　　keepalived2  ansible_ssh_host=192.168.146.137 ansible_ssh_pass="test"               	
>　　10.0.1.5 ansible_ssh_private_key_file=ssh_keys/10.0.1.5.key ansible_ssh_user=rootansible-doc
>
>　　ansible-doc -l :获取模块信息

## ansible-doc -s MOD_NAME: 获取指定模块的使用帮助
```
[root@node2 ~]# ansible-doc  -h　　
Usage: ansible-doc [options] [module...]
Show Ansible module documentation     显示Ansible模块文档
Options:
　　--version             show program's version number and exit    显示ansible-doc的版本号
　　-h, --help            show this help message and exit  显示命令参数API文档
　　-M MODULE_PATH, --module-path=MODULE_PATH   查询模块，--module-path=MODULE_PATH  指定模块的路径
　　Ansible modules/ directory
　　-l, --list            List available modules   显示已存在的所有模块列表
　　-s, --snippet         Show playbook snippet for specified module(s)   显示playbook制定模块的用法
　　-v                    Show version number and exit   显示ansible-doc的版本号
```

## Ansible模块
### command模块:

使用ansible自带模块执行命令 如果要用 > < | & ' ' 使用shell模块

```
[root@node2 ~/.ssh]# ansible all -m command -a "ls /root/.ssh"　　
node4 | success | rc=0 >>
authorized_keys
known_hosts
node3 | success | rc=0 >>
authorized_keys
known_hosts
[root@node2 ~/.ssh]# 
```

相关选项如下：　　
creates：一个文件名，当该文件存在，则该命令不执行
free_form：要执行的linux指令
chdir：在执行指令之前，先切换到该目录
removes：一个文件名，当该文件不存在，则该选项不执行
executable：切换shell来执行指令，该执行路径必须是一个绝对路径
### shell 模块:

调用bash执行命令 类似 cat /tmp/stanley.md | awk -F'|' '{print $1,$2}' &> /tmp/stanley.txt 这些复杂命令，即使使用shell也会失败，解决办法：写到脚本时，copy到远程，执行，再把需要的结果拉回执行命令的机器（执行Ansible命令的机器往往称为：Master机或者中控机或者堡垒机）。

　　注意：command和shell模块的核心参数直接为命令本身；而其它模块的参数通常为“key=value”格式；''
### copy模块： 

复制本地文件至远程服务器，并且能够改属性等

直接复制：

```
ansible  all -m copy -a "src=txt dest=/tmp mode=540"
```


生成内容的复制：

```shel
ansible  all -m copy -a "content='hellow' dest=/tmp/test mode=540"
ansible  all -m shell -a "cat /tmp/test mode=540"
```

注意：这两种方法是互斥的，即src和content不能同时使用
相关选项如下：　　
backup：在覆盖之前，将源文件备份，备份文件包含时间信息。有两个选项：yes|no
content：用于替代“src”，可以直接设定指定文件的值
dest：必选项。要将源文件复制到的远程主机的绝对路径，如果源文件是一个目录，那么该路径也必须是个目录
directory_mode：递归设定目录的权限，默认为系统默认权限
force：如果目标主机包含该文件，但内容不同，如果设置为yes，则强制覆盖，如果为no，则只有当目标主机的目标位置不存在该文件时，才复制。默认为yes
others：所有的file模块里的选项都可以在这里使用
src：被复制到远程主机的本地文件，可以是绝对路径，也可以是相对路径。如果路径是一个目录，它将递归复制。在这种情况下，如果路径使用“/”来结尾，则只复制目录里的内容，如果没有使用“/”来结尾，则包含目录在内的整个内容全部复制，类似于rsync。

### file模块：

设置文件属性

-a "path=PATH state=directory"  # 创建目录　　

```shell[root@node2 ~]# ansible all -m file -a "path=/tmp/hehe state=directory"

```

　　


-a "path=PATH  src=FILE  state=link"    #创建链接文件
　　
[root@node2 ~]# ansible all -m file -a "path=/root/haha src=/tmp/hehe state=link" 


-a "path=PATH  state=absent"    #删除文件
[root@node2 ~]# ansible all -m file -a "path=/root/haha state=absent"


　　相关选项如下：
force：需要在两种情况下强制创建软链接，一种是源文件不存在，但之后会建立的情况下；另一种是目标软链接已存在，需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no　　

group：定义文件/目录的属组
mode：定义文件/目录的权限
owner：定义文件/目录的属主
path：必选项，定义文件/目录的路径
recurse：递归设置文件的属性，只对目录有效
　　
src：被链接的源文件路径，只应用于state=link的情况
　　
dest：被链接到的路径，只应用于state=link的情况
　　
state：
　　directory：如果目录不存在，就创建目录
　　file：即使文件不存在，也不会被创建
　　link：创建软链接
　　hard：创建硬链接
　　touch：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间
　　absent：删除目录、文件或者取消链接文件
　　

　　fetch模块： 从远程服务器拉取文件至本机，只能fetch文件，不能fetch目录,如果拉目录，先tar/zip 再拉到本机即可
　　
[root@node2 ~]# ansible all -m fetch -a "src=/tmp/txt dest=/root/txt.txt"
　　cron模块: 管理cron计划任务
　　
[root@node2 ~]# ansible all -m corn -a "minute='*/5' job='/usr/sbin/ntpdate 172.16.0.1 &> /dev/null' name='Synctime'" #每5分钟同步一下时间
　　
[root@node2 ~]# ansible all -m corn -a "state=absent name='Synctime'" #删除上面的定时任务
　　相关选项如下：
　　

- a "": 设置管理节点生成定时任务　　
action: cron

backup=    # 如果设置，创建一个crontab备份
　　
cron_file=          #如果指定, 使用这个文件cron.d，而不是单个用户crontab
　　
day=       # 日应该运行的工作( 1-31, *, */2, etc )
　　
hour=      # 小时 ( 0-23, *, */2, etc )
　　
job=       #指明运行的命令是什么
　　
minute=    #分钟( 0-59, *, */2, etc )
　　
month=     # 月( 1-12, *, */2, etc )
　　
name=     #定时任务描述
　　
reboot    # 任务在重启时运行，不建议使用，建议使用special_time
　　
special_time       # 特殊的时间范围，参数：reboot（重启时）,annually（每年）,monthly（每月）,weekly（每周）,daily（每天）,hourly（每小时）
　　


state        #指定状态，prsent表示添加定时任务，也是默认设置，absent表示删除定时任务
　　


user         # 以哪个用户的身份执行
　　
weekday      # 周 ( 0-6 for Sunday-Saturday, *, etc )
　　

　　yum模块：yum安装软件，也有apt,zypper
　　

[root@node2 ~]# ansible all -m yum -a "name=httpd state=latest" #安装httpd包　　

　　相关选项如下：
　　

conf_file         #设定远程yum安装时所依赖的配置文件。如配置文件没有在默认的位置。　　
disable_gpg_check    #是否禁止GPG checking，只用于`present' or `latest'。
　　
disablerepo   #临时禁止使用yum库。 只用于安装或更新时。
　　
enablerepo    #临时使用的yum库。只用于安装或更新时。
　　
name=            #所安装的包的名称
　　
state               #present安装， latest安装最新的, absent 卸载软件。
　　
update_cache  #强制更新yum的缓存。
　　

　　service模块: 服务程序管理
　　

[root@node2 ~]# ansible all -m service -a "name=httpd state=restarted"  #重启httpd　　
[root@node2 ~]# ansible all -m service -a "name=httpd  enabled=true"    #开机启动
　　

　　相关选项如下：
　　

arguments         #命令行提供额外的参数　　
enabled           #设置开机启动。
　　
name=             #服务名称
　　
runlevel          #开机启动的级别，一般不用指定。
　　
sleep             #在重启服务的过程中，是否等待。如在服务关闭以后等待2秒再启动。


state     #started启动服务， stopped停止服务， restarted重启服务，>　　

　　group模块: 组管理
　　

[root@node2 ~]# ansible-doc -s group　　
- name: 添加或删除组

action: group
　　
gid       # 设置组的GID号
　　
name=     # 管理组的名称
　　
state     # 指定组状态，默认为创建，设置值为absent为删除
　　
system    # 设置值为yes，表示为创建系统组
　　

　　User模块:用户管理
　　

-a ""　　
action: user
　　
comment    # 用户的描述信息
　　
createhom  # 是否创建家目录
　　
force      # 在使用`state=absent'是, 行为与`userdel --force'一致.
　　
group      # 指定基本组
　　
groups     # 指定附加组，如果指定为('groups=')表示删除所有组
　　
home       # 指定用户家目录
　　
login_class     #可以设置用户的登录类 FreeBSD, OpenBSD and NetBSD系统.
　　
move_home       # 如果设置为`home='时, 试图将用户主目录移动到指定的目录
　　
name=           # 指定用户名
　　
non_unique      # 该选项允许改变非唯一的用户ID值
　　
password        # 指定用户密码
　　
remove          # 在使用 `state=absent'时, 行为是与 `userdel --remove'一致.
　　
shell           # 指定默认shell
　　
state           #设置帐号状态，不指定为创建，指定值为absent表示删除
　　
system          # 当创建一个用户，设置这个用户是系统用户。这个设置不能更改现有用户。
　　
uid             #指定用户的uid
update_password  # 更新用户密码
expires         #指明密码的过期时间
ansible all -m user -a 'name=magedu home=/tmp/magedu/ shell=/bin/bash uid=2000 comment="test user" group=root'
　　

　　ping 模块： 检测主机存活
　　setup模块：获取指定主机的facts。
　　
facts就是变量，内建变量 。每个主机的各种信息，cpu颗数、内存大小等。会存在facts中的某个变量中。调用后返回很多对应主机的信息，在后面的操作中可以根据不同的信息来做不同的操作。如redhat系列用yum安装，而debian系列用apt来安装软件。
　　

ansible node3 -m setup　　

　　selinux模块： 管理selinux
　　
关闭selinux
　　

ansible all -m selinux -a 'state=disabled'　　

conf     #指定应用selinux的配置文件。　　
state=enforcing|permissive|disabled      #对应于selinux配置文件的SELINUX。
　　
policy=targeted|minimum|mls     #对应于selinux配置文件的SELINUXTYPE
　　

　　script模块：发送脚本到各被管理节点，并执行;不需要参数
　　

ansible all -m script -a 'test.sh' #直接在-a 后面指定脚本即可　　

　　未完待续......
　　最后打个广告，Stanley老师的Ansible权威指南，你，值得拥有

DSC0007.png (64.81 KB, 下载次数: 0)

下载附件  保存到相册

2017-6-9 08:59 上传





