---
layout: post
title: web3与小狐狸的那些事
category: javascript
---

## 关于web3

## version

    主要用于获取当前连接的ethereum节点信息

* api  

        Web3.js 版本号
        eg:
            "0.20.6"
            "1.0.0-beta.35"(latest)
* node

        ethereum 节点信息
        eg: 
            "Mist/v0.9.3/darwin/go1.4.1"  
            "EthereumJS TestRPC/v2.1.5/ethereum-js"
* network  

        ethereum 节点网络号
* ethereum

        ethereum 协议版本号
* whisper

        ethereum whisper(用于分布式消息,一种信息检索协议) 协议版本号 
    

## net
* listening  

        ethereum 节点 是否在监听网络连接(服务是否存活)
* peerCount

        ethereum 节点 邻居数量
## eth
* defaultAccount  

        默认值 undefined
        获取当前设置的默认账户地址
        可以直接对其赋值为任一 ethereum wallet 账户地址
        用于以下方法的默认值参数 from
        web3.eth.sendTransaction 
        web3.eth.call
        可以指定 from 参数值 覆盖默认值
* defaultBlock
        
        默认值'latest'(Number/String)
        获取查询链上信息时指定的默认块高(block number)
        用于以下方法的默认值参数 defaultBlock
        web3.eth.getBalance()
        web3.eth.getCode()
        web3.eth.getTransactionCount()
        web3.eth.getStorageAt()
        web3.eth.call()
        contract.myMethod.call()
        contract.myMethod.estimateGas()
        可以指定 defaultBlock 参数值 覆盖默认值
* syncing

        获取区块节点是否在同步
        同步时 返回块高信息 startingBlock: 300,currentBlock: 312,highestBlock: 512
        没有同步则返回 false
* isSyncing

        区块开始同步、更新、停止回调注册方法
* coinbase

        获取矿工奖励地址
* accounts

        获取连接节点下账户列表
* blockNumber

        获取节点当前区块高度(block number)
* getBalance

        获取账户余额 
        可选参数:
        defaultBlock 指定块高余额 默认值是 'latest'(最新的块)
        callback    异步http请求
* getBlock

        获取给定块高的信息
        Returns a block matching the block number or block hash.
* getBlockTransactionCount

        获取指定块高的交易数量
        Returns the number of transaction in a given block.
* getTransaction

        获取指定tx_id的信息
        Returns a transaction matching the given transaction hash.
* sendTransaction

        仅支持发送未签名的交易
        一般用于local node 节点管理私钥
        only supports sending unsigned transactions
        from/to/value/gas/gasPrice/data/nonce
        data:
            byte string or code for contract-creation transaction
* sendRawTransaction

        发送已签名的交易

## db

## shh

### common utils functions

## 关于小狐狸(Metamask)
* 账户系统(钱包功能)

* rpc(HttpProveder)接管读/写入区块链

## 这里主要说说 rpc 接管的实现:

### 关于 Metamask 的猜想
关于这个实现, 在看 Metamask 源码之前我有以下几种猜想：  

    直接覆写web3.js api 的一些方法，比如 sendTransaction、sendRawTransaction

    通过chrome 插件开发提供的接口 webRequest 拦截http请求

带着这两个猜想再去看代码，最终发现之前的猜想还是沾了点边的，不过人家的实现要比上面的猜想精妙的多。

### chrome 插件基本结构
首先我们从chrome 扩展程序基本结构说起：  

    contentscripts.js
        插件中唯一拥有操作当前活动标签页面dom权限的js
    background.js
        全局运行的js(类似于`插件后台`)
    propub.html
        插件界面UI

    插件中的js之间可以通过postMessage接口通信

### Metamask(v4.9.3) 源码探寻
在 Metamask 中的 contentscripts.js (10~12、26~41行) 中
```javascript
    const inpageContent = fs.readFileSync(path.join(__dirname, '..', '..', 'dist', 'chrome', 'inpage.js')).toString()
    const inpageSuffix = '//# sourceURL=' + extension.extension.getURL('inpage.js') + '\n'
    const inpageBundle = inpageContent + inpageSuffix
    /**
    * Creates a script tag that injects inpage.js
    */
    function setupInjection () {
    try {
        // inject in-page script
        var scriptTag = document.createElement('script')
        scriptTag.textContent = inpageBundle
        scriptTag.onload = function () { this.parentNode.removeChild(this) }
        var container = document.head || document.documentElement
        // append as first child
        container.insertBefore(scriptTag, container.children[0])
    } catch (e) {
        console.error('Metamask injection failed.', e)
    }
    }
```
实现了在当前活动标签页面注入js的功能 具体注入的js内容在 inpage.js 中 核心代码(inpage.js 22~40行)
```javascript
    // compose the inpage provider
    var inpageProvider = new MetamaskInpageProvider(metamaskStream)
    //
    // setup web3
    //
    if (typeof window.web3 !== 'undefined') {
    throw new Error(`MetaMask detected another web3.
        MetaMask will not work reliably with another web3 extension.
        This usually happens if you have two MetaMasks installed,
        or MetaMask and another web3 extension. Please remove one
        and try again.`)
    }
    var web3 = new Web3(inpageProvider)
    web3.setProvider = function () {
    log.debug('MetaMask - overrode web3.setProvider')
    }
    log.debug('MetaMask - injected web3')
```
这段代码主要实现了给当前活动页面提供了一个 HttpProveder 为 MetamaskInpageProvider 的全局变量 `web3`

其中 MetamaskInpageProvider 的实现在他们内部的一个js库 `metamask-inpage-provider` 中

我们继续看看 MetamaskInpageProvider 的实现 metamask-inpage-provider/index.js

```javascript
//index.js (70~113行)
MetamaskInpageProvider.prototype.send = function (payload) {
    const self = this

    let selectedAddress
    let result = null
    switch (payload.method) {

        case 'eth_accounts':
        // read from localStorage
        selectedAddress = self.publicConfigStore.getState().selectedAddress
        result = selectedAddress ? [selectedAddress] : []
        break

        case 'eth_coinbase':
        // read from localStorage
        selectedAddress = self.publicConfigStore.getState().selectedAddress
        result = selectedAddress || null
        break

        case 'eth_uninstallFilter':
        self.sendAsync(payload, noop)
        result = true
        break

        case 'net_version':
        const networkVersion = self.publicConfigStore.getState().networkVersion
        result = networkVersion || null
        break

        // throw not-supported Error
        default:
        var link = 'https://github.com/MetaMask/faq/blob/master/DEVELOPERS.md#dizzy-all-async---think-of-metamask-as-a-light-client'
        var message = `The MetaMask Web3 object does not support synchronous methods like ${payload.method} without a callback parameter. See ${link} for details.`
        throw new Error(message)
    }

    // return the result
    return {
        id: payload.id,
        jsonrpc: payload.jsonrpc,
        result: result,
    }
}
```
接着我们再看看 web3.js 关于发送http请求的代码
## web3.js 源码探寻 （v0.20.6）
```javascript
//(4306~4327行)
HttpProvider.prototype.prepareRequest = function (async) {
    var request;

    if (async) {
        request = new XHR2();
        request.timeout = this.timeout;
    } else {
        request = new XMLHttpRequest();
    }

    request.open('POST', this.host, async);
    if (this.user && this.password) {
        var auth = 'Basic ' + new Buffer(this.user + ':' + this.password).toString('base64');
        request.setRequestHeader('Authorization', auth);
    } request.setRequestHeader('Content-Type', 'application/json');
    if(this.headers) {
        this.headers.forEach(function(header) {
            request.setRequestHeader(header.name, header.value);
        });
    }
    return request;
};
//(4336~4354行)
HttpProvider.prototype.send = function (payload) {
    var request = this.prepareRequest(false);

    try {
        request.send(JSON.stringify(payload));
    } catch (error) {
        throw errors.InvalidConnection(this.host);
    }

    var result = request.responseText;

    try {
        result = JSON.parse(result);
    } catch (e) {
        throw errors.InvalidResponse(request.responseText);
    }

    return result;
};
```
通过 Metamask MetamaskInpageProvider 与 web3.js HttpProvider 的对比，我们发现它们都实现了send方法

web3.js 的默认(provider) HttpProvider send方法 使用同步的方式通过xhr请求节点的rpc接口 获取相关的信息

Metamask MetamaskInpageProvider send 则覆写了 web3.js HttpProvider send 
如何达到覆写 ？ 因为上面我们说了 Metamask contentscripts.js 向当前页面注入了全局的 web3 实例 其中生成该实例的时候传入的 provider 是 MetamaskInpageProvider 的实例  `var web3 = new Web3(inpageProvider)`

到此 Metamask 插件 rpc(同步请求) 接管的实现机制已经分析完毕! 下次会补上 rpc 异步请求部分

有任何疑问或建议欢迎讨论.