---
title: chromedriver与chrome版本映射表
date: 2018-05-02 04:04:35
tags:
---

看到网上基本没有最新的chromedriver与chrome的对应关系表，便兴起整理了一份如下，希望对大家有用：

http://chromedriver.storage.googleapis.com/2.9/notes.txt

```bash

echo "" >ch.list 
for i in `curl -s  http://npm.taobao.org/mirrors/chromedriver| grep -e "chromedriver/[0-9].[0-9]*"| awk -F'/' '{print $4}'`
do
 curl -s  http://npm.taobao.org/mirrors/chromedriver/$i/notes.txt|grep -v "fails" |grep -e"v[0-9]*[.\-][0-9]*">>ch.list 
done
```

结果如下：

```shell
 cat ch.list| awk  -F'V| ' '{if($1=="Supports"){print "Supports Chrome " $3$4}else{print $2$3}}'
 #用ｐｒｉｎｔｆ会混乱

```



    ChromeDriver v2.9(2014-01-31)---------->Chrome:v31-34
    ChromeDriver v2.8(2013-12-16)---------->Chrome:v30-33
    ChromeDriver v2.7(2013-11-22)---------->Chrome:v30-33
    ChromeDriver v2.6(2013-11-04)---------->Chrome:v29-32
    ChromeDriver v2.5(2013-11-01)---------->Chrome:v29-32
    ChromeDriver v2.4(2013-09-30)---------->Chrome:v29-32
    ChromeDriver v2.37(2018-03-16)---------->Chrome:v64-66
    ChromeDriver v2.36(2018-03-02)---------->Chrome:v63-65
    ChromeDriver v2.35(2018-01-10)---------->Chrome:v62-64
    ChromeDriver v2.34(2017-12-10)---------->Chrome:v61-63
    ChromeDriver v2.33(2017-10-03)---------->Chrome:v60-62
    ChromeDriver v2.32(2017-08-30)---------->Chrome:v59-61
    ChromeDriver v2.3(2013-09-02)----------
    ChromeDriver v2.31(2017-07-21)---------->Chrome:v58-60
    ChromeDriver v2.30(2017-06-07)---------->Chrome:v58-60
    ChromeDriver v2.29(2017-04-04)---------->Chrome:v56-58
    ChromeDriver v2.28(2017-03-09)---------->Chrome:v55-57
    ChromeDriver v2.27(2016-12-23)---------->Chrome:v54-56
    ChromeDriver v2.26(2016-12-09)---------->Chrome:v53-55
    ChromeDriver v2.25(2016-10-25)---------->Chrome:v53-55
    ChromeDriver v2.24(2016-09-09)---------->Chrome:v52-54
    ChromeDriver v2.23(2016-08-04)---------->Chrome:v51-53
    ChromeDriver v2.22(2016-06-06)---------->Chrome:v49-52
    ChromeDriver v2.2(2013-08-06)----------
    ChromeDriver v2.21(2016-01-28)---------->Chrome:v46-50
    ChromeDriver v2.20(2015-10-08)---------->Chrome:v43-48
    ChromeDriver v2.19(2015-08-28)---------->Chrome:v43-47
    ChromeDriver v2.18(2015-08-19)---------->Chrome:v43-46
    ChromeDriver v2.15(2015-03-26)---------->Chrome:v40-43
    ChromeDriver v2.14(2015-01-28)---------->Chrome:v39-42
    ChromeDriver v2.13(2014-12-10)---------->Chrome:v38-41
    ChromeDriver v2.12(2014-10-27)---------->Chrome:v36-40
    ChromeDriver v2.11(2014-10-07)---------->Chrome:v36-40
    ChromeDriver v2.10(2014-05-01)---------->Chrome:v33-36
    
http://chromedriver.storage.googleapis.com/index.html