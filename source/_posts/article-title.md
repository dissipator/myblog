---
title: oracle 11g 在centos7上静默安装与安装时的错误处理
date: 2017-10-07 17:54:09
tags:
---
 分类：
oracle
版权声明：本文为博主原创文章，未经博主允许不得转载。
本次（2017-03-11）修改：
1）修改程序安装目录名   /home ---> /data
2）删减了一些不必要的包（ksh）
3）增加了rlwrap 一个可以在sqlplus中可以使用键盘方向键来回找历史命令。
4）增加了一些关键的截图，为帮助有需要的朋友理好知道安装进度
5）蓝色字体、双#号是新增说明

# 1、准备系统、软件
#oracle 11g：
linux.x64_11gR2_database_2of2.zip
linux.x64_11gR2_database_1of2.zip
#SYSTEM
CentOS7 X86_64
# 2、安装依赖库
 
#下载安装pdksh
 
rpm -ivh pdksh-5.2.14-37.el5_8.1.x86_64.rpm
##： 安装这个pdksh rpm包时可能会出现与ksh冲突问题，如果不使用ksh可以把ksh卸载了，我安装了非常多次发现并不影响使用----（2017-03-11）
#安装其它依赖
yum -y install binutils compat-libcap1 compat-libstdc++ gcc gcc-c++ glibc glibc-devel libgcc libstdc++ libstdc++-devel libaio sysstat libaio-devel elfutils-libelf-devel unixODBC unixODBC-devel
##： 删除了ksh安装包
# 3、用户目录创建
groupadd oinstall
groupadd dba
useradd -m -g oinstall -G dba oracle
echo "oracle:password" | chpasswd
mkdir -p /home/oracle/ora11g
chown -R oracle:oinstall /home/oracle/ora11g
chmod -R 775 /home/oracle/ora11g

# 4、系统配置
#内核参数调整
cat >> /etc/sysctl.conf <<EOF
fs.aio-max-nr = 3145728
fs.file-max = 6815744
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 142
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576 
EOF
#配置全局变量
cat >> /etc/profile <<EOF
if [ $USER = "oracle" ]; then
   if [ $SHELL = "/bin/ksh" ];then
    ulimit -p 16384
    ulimit -n 65536
     else
    ulimit -u 16384 -n 65536
   fi
fi
EOF
##：这个环境变量发现并没有什么用（重复配置），因为后面配置文件句柄数时已经永久配置了参数。
#配置oracle用户变量
cat >> /data/oracle/.bash_profile <<EOF
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=$(hostname)
export ORACLE_BASE=/data/oracle/ora11g
export ORACLE_HOME=/data/oracle/ora11g/product/11.2.0/db_1
export ORACLE_SID=orcl11g
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$PATH
#以下配置在参考别人写时是要配置的，但是我加上后，系统命令无法执行，就直接注释了
#export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib64:/usr/lib:/usr/lib64:/usr/local/lib64
#export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
#export LD_ASSUME_KERNEL=2.6.18
##：直接删除了
export NLS_LANG="american_america.UTF8"
export NLS_LANG="AMERICAN_AMERICA.US7ASCII"
EOF
#给oracle用户配置句柄数和文件打开数
cat >> /etc/security/limits.conf <<EOF
oracle soft nproc 2048
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
EOF
 
#配置oracle用户变量
cat >> /home/oracle/.bashrc <<EOF
alias sysdba='sqlplus "/ nolog"'
EOF

#配置oracle系统配置文件
cat >> /etc/oraInst.loc <<EOF
inventory_loc=/data/oracle/ora11g/oraInventory
inst_group=oinstall
EOF

#授权
chmod 664 /etc/oraInst.loc

#加载内核参数
sysctl -p

#给安装文件授权，我这里放在oracle home目录下
chown -R oracle:oinstall /home/oracle/database

#添加swap文件
#虚拟机没有或者不够swap空间
dd if=/dev/zero of=/data/swap4g bs=1M count=4096
mkswap /data/swap4g
chmod 600 /data/swap4g
swapon /data/swap4g

##：修改了文件/home/swap --- > /data/swap4g

# 5、安装、安装排错
#解压安装文件
#配置静默安装应答文件
su oracle ; cd ~
cp /home/oracle/database/response/* .
#配置初始化安装文件
sed -i 's/oracle.install.option=.*/oracle.install.option=INSTALL_DB_SWONLY/g' db_install.rsp
sed -i "s/ORACLE_HOSTNAME=.*/ORACLE_HOSTNAME=$(hostname)/g" db_install.rsp
sed -i 's/UNIX_GROUP_NAME=.*/UNIX_GROUP_NAME=oinstall/g' db_install.rsp
sed -i 's/INVENTORY_LOCATION=.*/INVENTORY_LOCATION=\/data\/oracle\/ora11g\/oraInventory/g' db_install.rsp
sed -i 's/SELECTED_LANGUAGES=.*/SELECTED_LANGUAGES=en,zh_CN/g' db_install.rsp
sed -i 's/ORACLE_HOME=.*/ORACLE_HOME=\/data\/oracle\/ora11g\/product\/11.2.0\/db_1/g' db_install.rsp
sed -i 's/ORACLE_BASE=.*/ORACLE_BASE=\/data\/oracle\/ora11g/g' db_install.rsp
sed -i 's/oracle.install.db.InstallEdition=.*/oracle.install.db.InstallEdition=EE/g' db_install.rsp
sed -i 's/oracle.install.db.isCustomInstall=.*/oracle.install.db.isCustomInstall=true/g' db_install.rsp
sed -i 's/oracle.install.db.DBA_GROUP=.*/oracle.install.db.DBA_GROUP=dba/g' db_install.rsp
sed -i 's/oracle.install.db.OPER_GROUP=.*/oracle.install.db.OPER_GROUP=oinstall/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.type=.*/oracle.install.db.config.starterdb.type=GENERAL_PURPOSE/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.globalDBName=.*/oracle.install.db.config.starterdb.globalDBName=ora11g/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.SID=.*/oracle.install.db.config.starterdb.SID=orcl/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.characterSet=.*/oracle.install.db.config.starterdb.characterSet=AL32UTF8/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.memoryOption=.*/oracle.install.db.config.starterdb.memoryOption=true/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.password.ALL=.*/oracle.install.db.config.starterdb.password.ALL=oracle/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.control=.*/oracle.install.db.config.starterdb.control=DB_CONTROL/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.dbcontrol.enableEmailNotification=.*/oracle.install.db.config.starterdb.dbcontrol.enableEmailNotification=true/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.dbcontrol.emailAddress=.*/oracle.install.db.config.starterdb.dbcontrol.emailAddress=test@test.com/g' db_install.rsp
sed -i 's/oracle.install.db.config.starterdb.dbcontrol.SMTPServer=.*/oracle.install.db.config.starterdb.dbcontrol.SMTPServer=smtp.test.com/g' db_install.rsp
sed -i 's/DECLINE_SECURITY_UPDATES=.*/DECLINE_SECURITY_UPDATES=true/g' db_install.rsp
chmod 640 db_install.rsp
##：修改目录配置/home ---> /data
##：修正在sed 参数  

#配置监听应答文件
sed -i 's/INSTALL_TYPE=.*/INSTALL_TYPE=""custom""/g' netca.rsp

#配置数据库应答文件
sed -i 's#GDBNAME =.*#GDBNAME = "orcl11g"#g' dbca.rsp
sed -i 's#SID =.*#SID = "orcl11g"#g' dbca.rsp
sed -i 's/#SYSPASSWORD =.*/SYSPASSWORD = "oracle"/g' dbca.rsp
sed -i 's/#SYSTEMPASSWORD =.*/SYSPASSWORD = "oracle"/g' dbca.rsp

#安装
/home/oracle/database/runInstaller -silent -responseFile /home/oracle/db_install.rsp
#先使用上面命令检查系统环境合不合格，如果出现依赖库版本不对（一般是系统的版本高了，oracle要求的版本低一些）和一些内核参数检测不出来（并不是没有配置），这些可以忽略。如果其它的报错根据报错去给系统作相应的调整吧。
#排错只能看日志，没有其它更好的办法。
#比如以下错误都可以忽略
801:INFO: Error Message:PRVF-7543 : 操作系统内核参数 "semmni" 在节点 "centos7-6" 上没有适当的值 [应为 = "128"; 找到 = "0"]。
930:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "libaio-0.3.105 (i386)"
951:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "glibc-2.3.4-2.41 (i686)"
972:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "compat-libstdc++-33-3.2.3 (i386)"
984:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "compat-libstdc++-33-3.2.3 (x86_64)"
1050:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "libaio-devel-0.3.105 (i386)"
1071:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "libgcc-3.4.6 (i386)"
1092:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "libstdc++-3.4.6 (i386)"
1131:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "unixODBC-2.2.11 (i386)"
1152:INFO: Error Message:PRVF-7532 : 节点 "centos7-6" 上缺少程序包 "unixODBC-devel-2.2.11 (i386)"
##：新增错误信息

#以下命令是忽略那些可忽略参数的命令
/home/oracle/database/runInstaller -silent -ignorePrereq -responseFile /home/oracle/db_install.rsp
#检测安完成后，会提示用root用户执行以下面的命令去完成最后的安装
sh /home/oracle/ora11g/product/11.2.0/db_1/root.sh


##：到目前为止，oracle已经全部安装完成

# 6、创建实例、监听文件
#创建实例
dbca -silent -responseFile /home/oracle/dbca.rsp


#创建监听
netca /silent /responseFile /home/oracle/netca.rsp


#查看oracle的状态


# 7、安装rlwrap
yum install readline* ncurses-devel
tar xf rlwrap-0.30.tar.gz.zip
cd rlwrap-0.30
./configure
make
make install
#直接配置在.bash_profile里
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'

source .bash_profile


#里边涉及的一些敏感数据就不打码了，因为都在VM里跑的。。。
#主要参考文章出处：http://blog.csdn.net/dc666/article/details/50014693，非常感谢！