---
layout: post
title: 使用时间字符串创建js Date对象
category: javascript
---

创建Date对象的方式有如下几种:
```javascript
new Date();       //默认为当前日期
new Date(value);  //参数是1970-01-01 00:00:00 UTC 经过的毫秒数
new Date('December 17, 1995 03:24:00'); //时间字符串 RFC-2822
new Date('2017-05-14T00:00:00Z');        //时间字符串 ISO 8601
// Z表示时区 可以是 +HH:mm;-HH:mm
```
> **注意：**构造出的日期用来显示时，会被转换为本地时间（调用 toString 方法):

```javascript
> new Date();
Tue May 16 2017 23:40:20 GMT+0800 (CST)
```

这里记录下使用ISO 8601时间字符串标准创建Date对象遇到的问题,未完待续。。。。。。
