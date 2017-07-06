---
layout: post
title: express 源码查看笔记
category: node
---
### 关于版本的说明
对于了解node的同学想必对express都不陌生，如果不了解的可以先看看 [express 文档](http://www.expressjs.com.cn/)。
因为笔者使用的express的版本是4.x，所以本文都是基于4.x版本的，毕竟与3.x版本的差异挺大，尤其是路由模块。
### http server的创建 
让我们从http server 的创建开始，在express中我们一般这样创建http server：
```javascript
const http = require('http');
const express = require('express');
const app = express();
// 这里将app作为createServer的参数传入，这很关键
const server = http.createServer(app);
```
为什么要将app作为参数传入呢？如果你用的编辑器支持函数类型智能提示，或者你找到node的typescript声明文件并定位到createServer的声明处，你便明白了。
```typescript
function createServer(requestListener?: (request: IncomingMessage, response: ServerResponse) => void): Server;
```
哈哈，原来这是将app作为了requestListener,那么requestListener具体是什么呢?在什么时候执行呢?我们稍后深究，目前我们只需知道它是一个函数，并且需要传入类型分别为IncomingMessage和ServerResponse的两个参数。
### app到底是什么
app本身是用户自定义的变量，源于application的缩写。不过可能是因为express官网的例子定义的就是app，而且也挺符合语义的。所有大部分都用它了。通过上面的代码我们知道它被赋给了express()的返回值。现在让我们来扒开它真实的面纱吧。
首先看看导入的express变量是啥玩意：
```javascript
// express/lib/express.js 27行
exports = module.exports = createApplication;
// express/lib/express.js 36~56行
function createApplication() {
    var app = function(req, res, next) {
        app.handle(req, res, next);
    };
    ...
    return app;
}
```
咦，它不就是个应该传入3个参数的函数吗。是的，express() 返回的就是个函数。等等，上面我们说过它是要作为createServer函数实参的。现在结合requestListener的参数声明和app的定义来看，不就对上了吗。上一节我们曾留下个关于requestListener的疑问，接下来让我们进一步探索它吧。
### requestListener 
从字面意思来推测，这个可能是跟request相关的处理程序(函数)，createServer内部可能将其与request(比如request事件)关联起来。通过对app.handle函数断点跟踪调试，从call stack中我发现了确实是这样的，让我们看看相关的node内部相关的代码
```javascript
// _http_common.js 45~99行 parserOnHeadersComplete
function parserOnHeadersComplete(....) {
    ...
    skipBody = parser.onIncoming(parser.incoming, shouldKeepAlive);
}
// _http_server.js 262~463~547行 
function connectionListener(socket) {
    ...
    parser.onIncoming = parserOnIncoming
    ...
    function parserOnIncoming(req, shouldKeepAlive) {
        ...
        self.emit('request', req, res);
    }
}
// events.js 136~191行
EventEmitter.prototype.emit = function emit(type) {
    ...
    handler = events[type];
    ...
    emitTwo(handler, isFn, this, arguments[1], arguments[2]);
}
// // events.js 104行
function emitTwo(handler, isFn, self, arg1, arg2) {
    if (isFn)
        handler.call(self, arg1, arg2);
    ...
}
```
最终才执行app
```javascript
// express/lib/express.js 37行
var app = function(req, res, next) {
    app.handle(req, res, next);
};
```