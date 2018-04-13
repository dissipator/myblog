---
title: 批量scp脚本
date: 2018-04-12 06:17:23
tags:　linux,shell
---

#批量scp脚本 

## 脚本如下：

```bash
#########################################################################
# File Name: batch-scp.sh
# Author: lucas
# mail: dissipator_520@qq.com
# Created Time: 2018年04月12日 星期四 14时19分28秒
#########################################################################
#!/bin/bash
if [ -z "$1" ];then
	echo -e "\033[31m USAGE: $0 command ,example{Src_file|Src_dir Des_dir}\033[0m"
exit
fi
SRCFILE=$1
TOPATH=$2
if [ -f ./ip.ls ];then
	IPS=`cat ./ip.ls`
else
	echo -e "\033[31m 请自行创建目标主机清单文件,如下：\033[0m"
	cat <<EOF
192.168.1.1
192.168.1.2
EOF
	exit
fi
count=`cat ./ip.ls|wc -l `
echo "there will  copying to $count hosts "
for ip in $IPS
do
    echo -e "copy $SRCFILE to $ip:"
    
	echo -e "/003[31m ---------------------------\003[0m"
	scp -r $SRCFILE $ip:$TOPATH
	echo -e "copy felished"
	echo -e "/003[31m ---------------------------\003[0m"
done

#sed "1s/^/&1 /g" ip.ls.awp
#IP=`awk -v "I=1" '{if(I==$1)print $2}' ip.ls.swp `
#echo $IP

```

