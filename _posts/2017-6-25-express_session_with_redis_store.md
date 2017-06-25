---
layout: post
title: express 使用 redis 存储 session
category: node
---

### session 是什么？
session 这个词中文解释是‘会话’，在本文主要指请求客户端(浏览器或其他用户代理)与 http server 交互的会话。通俗的讲，一问一答便是一次会话。
### 为什么要引入 session?
众所周知，http 是一种无状态协议，也就是说多个 http 请求之间是互不相识、毫无关联的；http server 无法知晓某个请求是谁发起的。这大概是考虑到传输速度的因素才这样设计的吧。但是有时候我们希望某些请求之间能有关联，或者说 http server 能识别出请求的客户端。这时就需要一引入种新的数据存储机制了。
### 客户端 cookie 的引入
> cookie 是由客户端实现的数据存储机制，可以简单理解是包含多个键值对的列表。

基于上述新需求，客户端便使用 cookie 在本地存储少量的用户信息，server 端通过解析请求头部的 cookie 来获取客户端存储的数据。这样，上面提到的需求得到了很好解决。但是，由于用户信息比较敏感，直接存储在客户端始终觉得不妥，所以服务端的 session 便诞生了。
### 服务端 session
出于安全考虑，最终还是决定将原本直接存储在客户端 cookie 中的用户信息存储在服务端，当然这并不意味着客户端 cookie 就没用了，客户端 cookie 肯定是必要的，只是这次存储的数据是会话唯一标识 session id。因为 session id 是由服务端决定生成和存储的，所以才称为服务端 session。
### express 使用 session
介绍完基本概念，现在可以进入本文的主题了。
早先的 express 版本是集成了 session 的实现的，由于我用的了是 v4.x。所以需要使用 express-session 这个中间件了。首先安装 express-session
```bash
npm install express --save
```
然后在挂在路由之前应用这个中间件 app.js
```javascript
// some other codes include routers mount above
const session = require('express-session');
app.use(session({
    store: new RedisStore({
        host: "localhost",
		port: 6379
        // db: 0 默认 db-index 是0
    }),
    name: 'sid',
    cookie: {
        maxAge: 3600*24*30*1000
    },
    resave: false,
    saveUninitialized: false,
    secret: 'some string you can custom',
}));
```
这里解释下几个配置选项的含义：
* **store:** session 存储方案
* **name:** cookie 将要存储的 session id的键名 如 sid='xxxxxxxxxx';
* **maxAge:** cookie 过期的毫秒数
* **resave:** 服务端是否每次都重新保存 session
* **saveUninitialized:** 是否保存一个未初始化的 session (如设置为 true 则服务端会保存你未设置任何数据的 session)
* **secret:** session id 签名(加密)字符串

实例代码中配置了store 为 redis express-session默认使用的是 memory store 即存储在内存中。由于内存存储在服务器重启后便会丢失数据，所以要想实现 session 持久化保存就需要把 session 存储在数据库中，而 redis 又是很好的选择。
### redis 
安装express 中间件 connact-redis 
```bash
npm install connact-redis
```
最后再安装 redis 数据库并开启服务便可以愉快的玩耍了。
[redis 中文文档](https://gnuhpc.gitbooks.io/redis-all-about/content/)