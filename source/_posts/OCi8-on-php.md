---
title: OCi8 on php
date: 2018-04-13 10:18:56
tags:
---

# php with OCI8

使用php的常见问题是：编译php时忘记添加某扩展，后来想添加扩展，但是因为安装php后又装了一些东西如PEAR等，不想删除目录重装，那么此时就需要自己重新增加某模块支持了,Linux操作系统下可以用phpize给PHP动态添加扩展.下面就以扩展模块 oci8为例(php连接oracle数据库需要改扩展支持)做简单的说明

1. 下载Oracle客户端程序包，其中包含OCI、OCCI和JDBC-OCI等相关文件

   1.1 根据Linux系统选择对应的软件,以32位系统为例,所以下载如下文件:

   oracle-instantclient11.2-basic-11.2.0.3.0-1.i386.rpm

   oracle-instantclient11.2-devel-11.2.0.3.0-1.i386.rpm

   1.2 下载地址: <http://www.oracle.com/technetwork/database/features/instant-client/index-097480.html> (Oracle官网下载需要注册用户)

2. 安装oracle客户端,运行以下命令即可:

    rpm -ivh oracle-instantclient11.2-basic-11.2.0.3.0.i386.rpm

    rpm -ivh oracle-instantclient11.2-devel-11.2.0.3.0.i386.rpm

3. 安装oci8 php扩展

  3.1  下载oci8-1.4.10.tgz

  下载地址:<http://pecl.php.net/get/oci8-1.4.10.tgz>

  3.2 把下载文件上传至linux服务器,并进行解压

  命令:tar zxvf oci8-1.4.10.tgz#解压

  3.3  转到解压目录

  命令:cd oci8-1.4.10

  3.4  使用phpize准备 PHP 外挂模块的编译环境，会根据指定的环境变量生成编译时需要的makefile，phpize是属于php-devel的内容，所以centos下只要运行yum install php-devel进行安装即可 (注意:/usr/local/php/bin/phpize 为我的php目录,不同则需改之;如果是64位的系统，client改成client64)

  /usr/local/php/bin/phpize CFLAGS="-I/usr/lib/oracle/11.1/client" CXXFLAGS="-I/usr/lib/oracle/11.1/client"

  3.5  编译，安装

    要有与现有php完全相同的php压缩包。我用的是php-5.5.3.tar.gz。展开后进入里面的ext/oci8目录下,

    然后执行命令: /usr/local/php/bin/phpize #这是一个可执行的文本文件，要确保它在系统中

    会发现当前目录下多了一些configure文件，

    如果没报错，则运行命令;

    ./configure --with-php-config=/usr/local/php/bin/php-config --with-oci8=/usr/lib/oracle/11.1/client

    注意要先确保/usr/local/php/bin/php-config存在。如果你的php安装路径不是默认的，要改。

    再运行以下命令 ，然后它告诉你一个目录,你把该目录下的oci8.so拷贝到你php.ini中的extension_dir指向的目录中

    make 
    make install 
    1). 需要强调的是make的时候会报错，显示各种找不到库文件，需要对makefile文件进行修改加入oralce的运行库地址

    打开makefile，寻找INCLUDE，形式如下：

    INCLUDES = -I/usr/local/php/include/php -I/usr/include/oracle/10.2.0.3/client

    然后在末尾加上="-I/usr/lib/oracle/11.1/client，然后重新make就会成功了。

  2) 编译的时候会出现错误：

  ```
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:56:17: 错误：oci.h：没有那个文件或目录
  In file included from /data/lnmp1.4c/oci8-1.4.10/oci8.c:58:
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:113: 错误：expected specifier-qualifier-list before ‘OCIEnv’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:122: 错误：expected specifier-qualifier-list before ‘OCIEnv’
  In file included from /data/lnmp1.4c/oci8-1.4.10/oci8.c:58:
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:152: 错误：expected specifier-qualifier-list before ‘dvoid’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:165: 错误：expected specifier-qualifier-list before ‘ub4’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:172: 错误：expected specifier-qualifier-list before ‘OCIType’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:182: 错误：expected specifier-qualifier-list before ‘text’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:191: 错误：expected specifier-qualifier-list before ‘sword’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:207: 错误：expected specifier-qualifier-list before ‘OCIBind’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:230: 错误：expected specifier-qualifier-list before ‘OCIDefine’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:377: 错误：expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘php_oci_error’
  /data/lnmp1.4c/oci8-1.4.10/php_oci8_int.h:378: 错误：expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘php_oci_fetch_errmsg’
  ```

  ​

  error: oci8_dtrace_gen.h: No such file or directory

  如果需要 DTRACE:

  yum install systemtap-sdt-devel
  export PHP_DTRACE=yes
  如果不需要 DTRACE:
```
  modify the file 'php_oci8_int.h', change the 48th line 

  #include "oci8_dtrace_gen.h" to #undef HAVE_OCI8_DTRACE
```
  

    修改PHP.ini（/usr/local/php/etc/php.ini）
    
    在extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/"后增加一行：
    
    extension = "oci8.so"
    
    注意:要确保/usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/ 该目录下有oci8.so文件

  ​

4. 重启apache,让oci生效

6. 在web目录下创建phpinfo.php文件在其中输入一下内容，并通过web访问