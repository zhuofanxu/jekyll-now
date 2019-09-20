## 共识/出块
    21个节点轮流连续出12个块
    每0.5s/块
    一个区块是通过后续节点基于该区块的生产行为来间接确认的
    BFT级别区块不可逆：需要(2/3 + 1)*21 即15个节点的确认 15*12=180个块
    区块的确认分为两个阶段，第一个阶段是pre-commit阶段
    该阶段需要接受2/3+1个节点的确认表明
    超过2/3节点认可该区块。但是此时并不意味着超过2/3的节点已经了解到这个2/3确认信息。因而再次需要2/3的commit签名确认过程。 因此总共需要经历后续300多个块(大概3分钟)才最终确认不可逆

## 交易
    过期时间：很重要，如果被打包之前就过期了，交易就丢了。

    交易相关的状态数据被回滚：
        某账户提交的交易a在广播节点执行成功了(该节点能查到a产生的相关状态数据)，随后传递到BP节点时交易a过期了；或者期间该账户又提交了其他交易导致该交易a在BP节点执行失败。最终随着BP节点块数据的传递，之前广播节点a产生的相关状态数据会被回滚，交易a最终没有上链。

        系统发生微分叉，最终主链确定时，分支上的区块由于不能成为主链，当这些区块包含的交易不在主链的区块里，会被释放出来重新执行打包到基于主链的新区块，此时，这些交易极有可能是过期了的，因此这些之前被成功打包的交易最终也是被回滚的。


## eosstudio

    目前只支持主网连接scatter

## eosio.cdt

### 编译合约
    error: fatal failure: contract with no actions and trying to create dispatcher

    原因：输出的wasm文件名与合约class类名不一致。

## 账户

### 创建账户
    cleos system newaccount --stake-net "0.1 EOS" --stake-cpu "0.1 EOS" \ 
        --buy-ram-kbytes 8 {creator} {newaccount} {owner_pub} {active_pub}

### cpu/net staked
    自己可以给自己和其他账户 staked
    即使是给其他账户的 staked 只能是自己去 unstaked

### 使用WASM LLVM
    速度快、开发语言支持广泛(能被编译wasm的语言都支持)

## 合约

### multi_index scope
    分离数据，更快的查询
    提高数据读写并发量 r/w lock 可以基于code-->scope细粒度度来区分

    --lower 下边界 查询 >= {index} 的结果
    --upper 上边界 查询 < {index} 的结果