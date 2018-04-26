---
title: MySQL自带的性能压力测试工具mysqlslap详解
date: 2018-04-25 02:58:08
tags:

---

## 查看链接：

```
mysqladmin -uroot -p1234.com status

Uptime: 1370150  Threads: 1 （当前连接数） Questions: 79  Slow queries: 0  Opens: 33  Flush tables: 1  Open tables: 26  Queries per second avg: 0.000
mysql -uroot -p1234.com -e 'show status' | grep -i  Threads 
Delayed_insert_threads    0
Slow_launch_threads    0
Threads_cached    1
Threads_connected    1
Threads_created    2
Threads_running    1 ##（当前连接数）
```

##  查看最大连接数

```
mysql -uroot -p1234.com -e 'show variables' | grep max_connections
max_connections    500
```

## 解决方法：

想尽一切办法不重启

 

这种情况一般是进不去数据库了，修改配置文件得重启，对于线上的数据库风险太大了，进入数据库用sql修改，现在是进不去了 

 

**方法1：**

使用gdb工具 不用进入数据库，不用重启数据库 方法如下：

```
 gdb -p $(cat /data/mydata/xxx.pid) -ex "set max_connections=500" -batch
```



查看mysql pid位置的方法

 

在配置文件 my.cnf里查找

用 ps -ef | grep mysql 查找

```
mysql> show variables like '%pid%';
+---------------+----------------------+
| Variable_name | Value                |
+---------------+----------------------+
| pid_file      | /data/mydata/xxx.pid |
+---------------+----------------------+
1 row in set (0.00 sec)
```



```
修改完毕后 ，尝试重新进入数据库，并查看链接数
```

这种方法设置后，只是暂时的，数据库重启后，会变为原来的数值，要想永久，设置完后修改配置文件my.cnf

```

```

方法2

 

前提是还可以进入数据库

进入数据库

设置新的最大连接数为200：mysql> set GLOBAL max_connections=200

显示当前运行的Query：mysql> show processlist

显示当前状态：mysql> show status

退出客户端：mysql> exit

这种方法设置后，只是暂时的，数据库重启后，会变为原来的数值，要想永久，设置完后修改配置文件my.cnf

**方法3：**

需要重启数据库

修改 my.conf 

**max_connection = 1000;**

## 模拟mysql连接数过多 



```
#!/bin/bash
set j=2
while true 
do
        let "j=j+1"
/usr/local/mysql/bin/mysqlslap -a -c 500 -i 10 -uroot -p1234.com
done
```





# [MySQL自带的性能压力测试工具mysqlslap详解](http://www.ha97.com/5182.html)

下图是运行mysqlslap -a -c 500 -i 10 -uroot -p123456测试时mysql的连接进程数：

**使用语法如下：**
\# mysqlslap [options]

**常用参数 [options] 详细说明：**
--auto-generate-sql, -a 自动生成测试表和数据，表示用mysqlslap工具自己生成的SQL脚本来测试并发压力。

--auto-generate-sql-load-type=type 测试语句的类型。代表要测试的环境是读操作还是写操作还是两者混合的。取值包括：read，key，write，update和mixed(默认)。

--auto-generate-sql-add-auto-increment 代表对生成的表自动添加auto_increment列，从5.1.18版本开始支持。

--number-char-cols=N, -x N 自动生成的测试表中包含多少个字符类型的列，默认1--number-int-cols=N, -y N 自动生成的测试表中包含多少个数字类型的列，默认1--number-of-queries=N 总的测试查询次数(并发客户数×每客户查询次数)

--query=name,-q 使用自定义脚本执行测试，例如可以调用自定义的一个存储过程或者sql语句来执行测试。

--create-schema 代表自定义的测试库名称，测试的schema，MySQL中schema也就是database。

--commint=N 多少条DML后提交一次。

--compress, -C 如果服务器和客户端支持都压缩，则压缩信息传递。

--concurrency=N, -c N 表示并发量，也就是模拟多少个客户端同时执行select。可指定多个值，以逗号或者--delimiter参数指定的值做为分隔符。例如：--concurrency=100,200,500。

--engine=engine_name, -e engine_name 代表要测试的引擎，可以有多个，用分隔符隔开。例如：--engines=myisam,innodb。

--iterations=N, -i N 测试执行的迭代次数，代表要在不同并发环境下，各自运行测试多少次。

--only-print 只打印测试语句而不实际执行。

--detach=N 执行N条语句后断开重连。

--debug-info, -T 打印内存和CPU的相关信息。`

说明：
测试的过程需要生成测试表，插入测试数据，这个mysqlslap可以自动生成，默认生成一个mysqlslap的schema，如果已经存在则先删除。可以用`--only-print`来打印实际的测试过程，整个测试完成后不会在数据库中留下痕迹。

**各种测试参数实例（-p后面跟的是mysql的root密码）：**

测试同时不同的存储引擎的性能进行对比：
`# mysqlslap -a --concurrency=50,100 --number-of-queries 1000 --iterations=5 --engine=myisam,innodb --debug-info -uroot -p123456`

执行一次测试，分别50和100个并发，执行1000次总查询：
`# mysqlslap -a --concurrency=50,100 --number-of-queries 1000 --debug-info -uroot -p123456`

50和100个并发分别得到一次测试结果(Benchmark)，并发数越多，执行完所有查询的时间越长。为了准确起见，可以多迭代测试几次:
`# mysqlslap -a --concurrency=50,100 --number-of-queries 1000 --iterations=5 --debug-info -uroot -p123456`



**实例1**
说明:测试100个并发线程，测试次数1次，自动生成SQL测试脚本，读、写、更新混合测试，自增长字段，测试引擎为innodb，共运行5000次查询
**#mysqlslap -h127.0.0.1 -uroot -p123456789 --concurrency=100 --iterations=1 --auto-generate-sql --auto-generate-sql-load-type=mixed --auto-generate-sql-add-autoincrement --engine=innodb --number-of-queries=5000**
Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.351 seconds	　　　　	100个客户端（并发）同时运行这些SQL语句平均要花0.351秒
Minimum number of seconds to run all queries: 0.351 seconds
Maximum number of seconds to run all queries: 0.351 seconds
Number of clients running queries: 100	　　　　　　　　　　　　  总共100个客户端（并发）运行这些sql查询
Average number of queries per client:50	　　　　　　　　　　　　每个客户端（并发）平均运行50次查询（对应--concurrency=100，--number-of-queries=5000；5000/100=50）

**实例2**
**#mysqlslap -h127.0.0.1 -uroot -p123456789 --concurrency=100,500,1000 --iterations=1 --auto-generate-sql --auto-generate-sql-load-type=mixed --auto-generate-sql-add-autoincrement --engine=innodb --number-of-queries=5000 --debug-info**
Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.328 seconds
Minimum number of seconds to run all queries: 0.328 seconds
Maximum number of seconds to run all queries: 0.328 seconds
Number of clients running queries: 100
Average number of queries per client: 50

Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.358 seconds
Minimum number of seconds to run all queries: 0.358 seconds
Maximum number of seconds to run all queries: 0.358 seconds
Number of clients running queries: 500
Average number of queries per client: 10

Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.482 seconds
Minimum number of seconds to run all queries: 0.482 seconds
Maximum number of seconds to run all queries: 0.482 seconds
Number of clients running queries: 1000
Average number of queries per client: 5

User time 0.21, System time 0.78
Maximum resident set size 21520, Integral resident set size 0
Non-physical pagefaults 12332, Physical pagefaults 0, Swaps 0
Blocks in 0 out 0, Messages in 0 out 0, Signals 0
Voluntary context switches 36771, Involuntary context switches 1396

**实例3(自定义sql语句)**
**#mysqlslap -h127.0.0.1 -uroot -p123456789 --concurrency=100 --iterations=1 --create-schema=rudao --query='select \* from serverlist;' --engine=innodb --number-of-queries=5000 --debug-info**
Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.144 seconds
Minimum number of seconds to run all queries: 0.144 seconds
Maximum number of seconds to run all queries: 0.144 seconds
Number of clients running queries: 100
Average number of queries per client: 50

User time 0.05, System time 0.09
Maximum resident set size 6132, Integral resident set size 0
Non-physical pagefaults 2078, Physical pagefaults 0, Swaps 0
Blocks in 0 out 0, Messages in 0 out 0, Signals 0
Voluntary context switches 6051, Involuntary context switches 90

**实例4(指定sql脚本)**
**#mysqlslap -h127.0.0.1 -uroot -p123456789 --concurrency=100 --iterations=1 --create-schema=rudao --query=/tmp/query.sql --engine=innodb --number-of-queries=5000 --debug-info**
Warning: Using a password on the command line interface can be insecure.
Benchmark
Running for engine innodb
Average number of seconds to run all queries: 0.157 seconds
Minimum number of seconds to run all queries: 0.157 seconds
Maximum number of seconds to run all queries: 0.157 seconds
Number of clients running queries: 100
Average number of queries per client: 50

User time 0.07, System time 0.08
Maximum resident set size 6152, Integral resident set size 0
Non-physical pagefaults 2107, Physical pagefaults 0, Swaps 0
Blocks in 0 out 0, Messages in 0 out 0, Signals 0
Voluntary context switches 6076, Involuntary context switches 89