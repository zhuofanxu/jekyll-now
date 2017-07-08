---
layout: post
title: express 源码之路由
category: node
---

### express 路由模块核心 router
尽请期待.....


app.use(path:string, router: Router)
此时的 layer 的 handle 是一个 router 即 function router(req,res,next) { router.handle }。当 layer.handle_rquest 的时候，便会执行 router() 然后执行 router 内部的 router.handle() 且handle执行的上下文 this 为 layer 中 handle 保存的 router function