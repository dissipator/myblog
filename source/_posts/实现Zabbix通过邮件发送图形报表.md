---
title: 实现Zabbix通过邮件发送图形报表
date: 2018-04-27 01:19:29
tags: zabbix

---

# 实现Zabbix通过邮件发送图形报表

在使用Zabbix的过程中，我们通常会建立一些需要图形报表来汇总需要监控的Graph。
而下面的两个脚本，则是通过从Zabbix数据库中获取所有的图形数据，提供Zabbix的WEB接口将所有图形保存到本地，然后通过脚本以Email形式发送过来，作为每天的自动报表。

在本地创建/data/cscript 和 /data/graph 目录

```
#!/usr/bin/perl
use File::Path;
use DBI;
use Net::FTP;
#
#定义graph路径，判断graph目录是否存在，不存在则自动新建
my $path = '/data/graph';
if(-e $path) { rmtree($path); }
mkdir($path);
#
my $stime = `date +%Y%m%d`; chop($stime); $stime .= '1000';
if( length($stime) != 12 ) { print "Error get date"; exit; }
#
#指定截图图形的时间轴周期
my $period = 21600;    # 6 hours
#
#定义Web的登陆名及密码
my $login = 'admin';   # Zabbix Web User
my $pass = 'password'; # Zabbix Web User Password, must be URL Encoded
#
#定义FTP账号密码
my $ftp_site = 'ftp.corp.intra';
my $ftp_user_name = 'zabbix';
my $ftp_password = 'zabbix';
#
#定义cookie的路径
my $cook = "/tmp/cookie";
#
#指定链接数据库
my $dsn = 'DBI:mysql:zabbix:localhost'; # Connect MySQL DB "zabbix" on localhost
my $db_user_name = 'zabbix'; # MySQL DB user
my $db_password = 'dbpassword'; # MySQL DB user password
my $dbh = DBI->connect($dsn, $db_user_name, $db_password);
#
#查询存在哪些screen
my $sth = $dbh->prepare(qq{select a.name,a.hsize,a.vsize, b.resourceid, b.width, b.height,b.x,b.y from screens a,screens_items as b where a.screenid=b.screenid and a.templateid<=>NULL order by a.name});
$sth->execute();
my %screens;
#
# Get all graphs by using curl
while (my ($name,$hsize,$vsize, $id,$width,$height,$x,$y) = $sth->fetchrow_array())
{
#
#长度大于2位的是graph，小于2位的表示是MAP
if(length($id) > 2)
{
#print "$id => $ids\n";
#
#定义导出的文件路径及文件名
my $p = "$path/$name.$hsize.$vsize.$y.$x.$id.png";
#
#获取cookie，免除访问实际数据时需要认证
my $strcomm  = `curl  -D $cook -b $cook -d "request=&name=$login&password=$pass&autologin=1&enter=Sign+in"  localhost/zabbix/index.php`;
#
#获取图形文件
$strcomm  = `curl  -b $cook -F  "graphid=$id" -F "period=$period" -F "stime=$stime" -F "width=$width" -F "height=$height" localhost/zabbix/chart2.php > $p`;
}
#
#否则，小于2位的表示是MAP
else {
my $p = "$path/map.$name.$id.png";
my $strcomm  = `curl  -b $cook -F  "sysmapid=$id" localhost/zabbix/map.php > $p`;
 
#
#ftp到服务器上
my $ftp = Net::FTP->new
(
$FTP_Site,
Timeout => 30
) or die "could not connect.\n";
$ftp->login($ftp_user_name,$ftp_password) or die "Could not login.\n";
$ftp->binary,$ftp->message;
#$remotefile = "Lync.png";
#$localfile = "$path/$p";
$ftp->put($p) or die "put $remotefile fail.\n",$ftp->message;
$ftp->quit;
}
}
exit ;

```

email-pic.py

```shell
#! /usr/bin/env python
import os
import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEImage import MIMEImage
# 定义函数 _sendmail
def _sendmail(smtp_server,port,account,password,str_from,list_to,msg):
    smtp = smtplib.SMTP(smtp_server,port)
    smtp.ehlo()
    smtp.starttls()
    smtp.ehlo()
#    smtp.login(account, password)
    smtp.sendmail(str_from, list_to,msg)
    smtp.close()
 
# 定义函数 _get_pictures
def _get_pictures(image_dir):
#建立空列表Pictures
    pictures = []
#os.listdir 返回指定目录下的所有文件和目录名
    for f in os.listdir(image_dir):
# append 是在列表最后增加内容，这里是将list出来的信息f增加到Picture列表中
        pictures.append(f)
    return pictures
# 定义函数 _create_msg
def _create_msg(screen_name,screens,image_dir,str_from,list_to):
    msgRoot = MIMEMultipart('related')
 
# 定义邮件主题
    msgRoot['Subject'] = 'Zabbix Screen Report: %s' % screen_name
 
#定义发件人、收件人
    msgRoot['From'] = str_from
    msgRoot['To'] = ",".join(list_to)
    msgRoot.preamble = 'This is a multi-part message in MIME format.'
    # Encapsulate the plain and HTML versions of the message body in an
    # 'alternative' part, so message agents can decide which they want to display.
    msgAlternative = MIMEMultipart('alternative')
    msgRoot.attach(msgAlternative)
# 定义邮件正文内容
    msgText = MIMEText('This is the alternative plain text message.')
    msgAlternative.attach(msgText)
    contents = ""
# tuple 元组 定义hsize,vsize变量  
    contents += "<h1>Screen %s</h1><br>" % screen_name
    _,hsize,vsize,_,_,_,_,= tuple(screens[0].split('.'))
 
    contents +="<table>"
 
# sorted()是产生一个新的列表并排序   
    screens = sorted(screens)
    y= -1
    for f in screens:
# 将文件名以为.分割点
        items = f.split('.')
 
# 原文件名格式:$path/$name.$hsize.$vsize.$y.$x.$id.png
# 经过切片后取 image_Y,Image_x,image_ID
        # tuple 元组
        _,_,_,image_y,image_x,image_id,_ = tuple(items)
        #定义邮件中的图片文件名：image-screen_name-image_id
        image_name = "image-%s-%s" % (screen_name, image_id)
        #fp = open("test.txt",w)     直接打开一个文件，如果文件不存在则创建文件
        #关于open 模式：
        #w     以写方式打开，
        #a     以追加模式打开 (从 EOF 开始, 必要时创建新文件)
        #r+     以读写模式打开
        #w+     以读写模式打开 (参见 w )
        #a+     以读写模式打开 (参见 a )
        #rb     以二进制读模式打开
        #wb     以二进制写模式打开 (参见 w )
        #ab     以二进制追加模式打开 (参见 a )
        #rb+    以二进制读写模式打开 (参见 r+ )
        #wb+    以二进制读写模式打开 (参见 w+ )
        #ab+    以二进制读写模式打开 (参见 a+ )
        fp = open('%s/%s' % (image_dir,f), 'rb')
 
        #fp.read([size])                     #size为读取的长度，以byte为单位
        msgImage = MIMEImage(fp.read())
 
        #fp.close()  #关闭文件。python会在一个文件不用后自动关闭文件，不过这一功能没有保证，最好还是养成自己关闭的习惯。 
        #如果一个文件在关闭后还对其进行操作会产生ValueError
        fp.close()
 
        msgImage.add_header('Content-ID', "<%s>" % image_name)
        msgRoot.attach(msgImage)
#定义循环
        if y != image_y:
            if y!= -1:
                contents +="</tr>"
            y = image_y
            contents +="<tr>"
 
# 定义td中嵌套图片文件
        contents +="<td><img src='cid:%s'></td>" % image_name
 
# table结束   
    contents += "</table>"
# 定义邮件格式为HTML
    msgText = MIMEText(contents, 'html')
 
    msgAlternative.attach(msgText)
#    msgRoot.attach(msgAlternative)
    return msgRoot
# Create the root message and fill in the from, to, and subject headers
def main(str_from,list_to,image_dir):
    pictures = _get_pictures(image_dir)
# 定义screen name,如:  Citrix_APP_Server_Loading
    for screen_name in list(set([x.split('.')[0] for x in pictures ])):
# startswith 判断字串开始
# screens 是一组 相同前缀的文件,如: screens ['Zabbix_server.2.2.1.1.525.png', 'Zabbix_server.2.2.1.0.524.png']
        screens = [x for x in pictures if x.startswith(str(screen_name) + '.') ]
 
        msgRoot = _create_msg(screen_name,screens,image_dir,str_from,list_to)
 
#定义邮件服务器地址、端口
        _sendmail(smtp_server,port,'','',str_from,list_to,msgRoot.as_string())
# 定义发送邮件信息，发件人，收件人，图片目录
if __name__ == '__main__':
   smtp_server = '10.210.1.16'
   port = 25
   str_from = 'adm_zbx@corp.com.cn'
   list_to = [
                "roger.ling@corp.com.cn"
             ]
   image_dir = '/data/graph/maps'
   main(str_from,list_to,image_dir)
```

