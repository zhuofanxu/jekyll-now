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
new Date('hello');
// Z表示时区 可以是 +HH:mm;-HH:mm
```
> **注意：**构造出的日期用来显示时，会被转换为本地时间（调用 toString 方法):

```javascript
> new Date();
// Tue May 16 2017 23:40:20 GMT+0800 (CST)
```

这里记录下使用ISO 8601时间字符串标准创建Date对象遇到的问题。在chrome下,时间字符串日期和时间的分隔符可以是T或者是空格,两者都能正确的生成本地时间对象;
在safari下，只接受分隔符T，否则报Invalid Date错误，而且默认为UTC时间，生成date对象时(转为本地时间)会自动加减时区差，除非在时间字符串上加上时区:
```javascript
// chrome
> new Date('2017-05-14T10:30:20')
// Sun May 14 2017 10:30:20 GMT+0800 (CST)
> new Date('2017-05-14 10:30:20')
// Sun May 14 2017 10:30:20 GMT+0800 (CST)

// safari 默认为UTC时间
> new Date('2017-05-14T10:30:20')
// Sun May 14 2017 18:30:20 GMT+0800 (CST)

// 兼容两者(得到一致结果) 分隔符为T并带上时区
> new Date('2017-05-14T10:30:20+08:00')
// Sun May 14 2017 10:30:20 GMT+0800 (CST)
```
总结：firefox目前还没有去测，有时间再补上。在使用ISO 8601标准字符串构造date对象时，使用标准的T分隔符并带上时区，基本就能兼容现代各大浏览器了。
