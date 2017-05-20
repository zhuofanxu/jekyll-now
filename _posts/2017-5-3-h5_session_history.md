---
layout: post
title: Html5 session history api 使用
category: html5
---

Html5 新增的 session history api 主要包括以下方法：
### back
```javascript
window.history.back()     //等同于点击浏览器后退按钮
```

### forward
```javascript
window.history.forward()  //等同于点击浏览器前进按钮
```

### go
```javascript
window.history.go(index)  //该方法根据index从session history载入页面 
                          //参数index相对于当前页面(0)
```
以上三个方法比较简单，应用场景也比较明显：通过js操作页面的前进或后退。下面着重介绍另外两个方法以及相应的事件：

### pushState
> 浏览器历史记录可以看作一个「栈」。栈是一种后进先出的结构，可以把它想象成一摞盘子，用户每点开一个新网页，都会在上面加一个新盘子，叫「入栈」。用户每次点击「后退」按钮都会取走最上面的那个盘子，叫做「出栈」。而每次浏览器显示的自然是最顶端的盘子的内容。

该方法接受三个参数：
* state object：一个对象或者字符串，用于描述新记录的一些特性。这个参数会被一并添加到历史记录中，以供以后使用。这个参数是开发者根据自己的需要自由给出的。

* title：字符串，表示新页面的标题，目前基本上被所有浏览器忽略(也许将来用得上)

* URL：字符串，表示页面的url，可选参数，可以是绝对或者相对的，但必须与当前页面同源(location.origin)，否则会报错；缺省时默认为当前url。

```javascript
var stateObj = {};
window.history.pushState(stateObj, title, url);
```
执行pushState后，浏览器历史记录会新增一条记录，此时记录栈的顶端变成了新增的记录，地址栏也相应的改变。但浏览器不会试图加载或者验证该url。基于上述原因，pushState的应用场景变得丰富而灵活了。

### replaceState
用法基本上与pusState一致，差别在于该方法不会新增历史记录，而仅仅是修改当前的历史记录(栈顶记录);经典的应用场景是给当前页面加减上hash(#xxx/锚点)或者查询参数(?parameter=value)。

### 事件
#### popstate
> A popstate event is dispatched to the window every time the active history entry changes. If the history entry being activated was created by a call to pushState or affected by a call to replaceState, the popstate event's state property contains a copy of the history entry's state object. from the [MDN](https://developer.mozilla.org/en-US/docs/Web/API/History_API#The_popstate_event)

#### hashchange
当URL的片段标识符更改时，将触发hashchange事件 (跟在＃符号后面的URL部分，包括＃符号) 事件携带两个重要的属性：
* oldURL 变化前的URL
* newURL 变化后的URL
