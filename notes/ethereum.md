## 以太坊节点区块同步模式

### full mode
    在数据库中保存所有区块数据，但在同步时，只从远程节点同步 header 和 body 数据，state 和 receipt 数据则是在本地计算出来的。
    在 full 模式下，downloader 会同步区块的 header 和 body 数据组成一个区块，然后通过 blockchain 模块的 BlockChain.InsertChain 向数据库中插入区块。在 BlockChain.InsertChain 中，会逐个计算和验证每个块的 state 和 recepit 等数据，如果一切正常就将区块数据以及自己计算得到的 state、recepit 数据一起写入到数据库中。

### fast mode
    recepit 不再由本地计算，而是和区块数据一样，直接由 downloader 从其它节点中同步;state 数据并不会全部计算和下载。
    因为 fast 模式忽略了大部分 state 数据，并且使用网络直接同步 receipt 数据的方式替换了 full 模式下的本地计算，所以才比较快。

### light mode
    只同步区块头
