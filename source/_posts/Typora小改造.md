---
title: Typora小改造
date: 2018-04-12 02:33:58
tags: Typora
---

# 使用Typora 链接WebSocket

## 修改文件windows.html (line 82)

> 在</rable></li>后面添加收到的WebSocket信息接收element如下：

```html
<li>
    <span class="footer-word-count-info-line" style="font-weight: bold">
        <span class="footer-word-count-no-selection" data-lg="Panel">SHELL</span>
    </span>
</li>
<li><p id="shell-output"></p></li>

```

## 随后加入输入框和按钮

```html
<div class="footer-item footer-item-left"  id="terminal">
<label>SHELL:</label><input type="text" id='shell' name="shell" value="pwd" />
<button type="submit" onclick="execs()" class="footer-item-right footer-btn "  id="toggle-exec-btn">Exec</button>
</div>
```



## 增加js脚本

```js
	var ws;
    function make_terminal(element, size, ws_url,paramter) {
        ws = new WebSocket(ws_url);
        ws.onopen = function (event) {
            ws.send(JSON.stringify({"parameter":paramter}));
            ws.onmessage = function (event) {
                json_msg = JSON.parse(event.data);
                console.log(json_msg);
                switch (json_msg[0]) {
                    case "stdout":
						element.innerHTML="message:" + json_msg[1];
                        break;
                    case "disconnect":
                        element.innerHTML="[Finished...]";
                        break;
                }
            };
            ws.close = function (argument) {console.log(argument);};
        };
    };
    var ws_scheme = window.location.protocol == "https:" ? "wss" : "ws";
    var ws_path = ws_scheme + '://127.0.0.1:8001/exec/';

	function execs() {
        var message = {
            common: $('#shell').val(),
        }
        if(document.body.classList.contains("show-word-count")){console.log(1);}else document.body.classList.add("show-word-count");
        make_terminal(document.getElementById('shell-output'), {rows: 1, cols: 90}, ws_path, message);
    };

```

