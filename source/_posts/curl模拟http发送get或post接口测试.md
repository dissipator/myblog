---
title: curl模拟http发送get或post接口测试
date: 2018-04-16 06:24:48
tags:　linux, curl

---

# curl模拟http发送get或post接口测试[转]

可参照：http://www.voidcn.com/blog/Vindra/article/p-4917667.html

一、get请求 

curl "http://www.baidu.com"  如果这里的URL指向的是一个文件或者一幅图都可以直接下载到本地

curl -i "http://www.baidu.com"  显示全部信息

curl -l "http://www.baidu.com" 只显示头部信息

curl -v "http://www.baidu.com" 显示get请求全过程解析

 wget "http://www.baidu.com"也可以

二、post请求

curl -d "param1=value1&param2=value2" "http://www.baidu.com"

三、json格式的post请求

curl -l -H "Content-type: application/json" -X POST -d '{"phone":"13521389587","password":"test"}' http://domain/apis/users.json

例如：

curl -l -H "Content-type: application/json" -X POST -d '{"ver": "1.0","soa":{"req":"123"},"iface":"me.ele.lpdinfra.prediction.service.PredictionService","method":"restaurant_make_order_time","args":{"arg2":"\"stable\"","arg1":"{\"code\":[\"WIND\"],\"temperature\":11.11}","arg0":"{\"tracking_id\":\"100000000331770936\",\"eleme_order_id\":\"100000000331770936\",\"platform_id\":\"4\",\"restaurant_id\":\"482571\",\"dish_num\":1,\"dish_info\":[{\"entity_id\":142547763,\"quantity\":1,\"category_id\":1,\"dish_name\":\"[0xe7][0x89][0xb9][0xe4][0xbb][0xb7][0xe8][0x85][0x8a][0xe5][0x91][0xb3][0xe5][0x8f][0x89][0xe7][0x83][0xa7][0xe5][0x8f][0x8c][0xe6][0x8b][0xbc][0xe7][0x85][0xb2][0xe4][0xbb][0x94][0xe9][0xa5][0xad]\",\"price\":31.0}],\"merchant_location\":{\"longitude\":\"121.47831425\",\"latitude\":\"31.27576153\"},\"customer_location\":{\"longitude\":\"121.47831425\",\"latitude\":\"31.27576153\"},\"created_at\":1477896550,\"confirmed_at\":1477896550,\"dishes_total_price\":0.0,\"food_boxes_total_price\":2.0,\"delivery_total_price\":2.0,\"pay_amount\":35.0,\"city_id\":\"1\"}"}}' http://vpcb-lpdinfra-stream-1.vm.elenet.me:8989/rpc

ps：json串内层参数需要格式化