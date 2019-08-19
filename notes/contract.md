## 合约基础

### 合约地址

    合约地址通过 sha3(creator, transaction_nonce)计算出

## 合约安全

### Re-Entrancy 

    攻击者通过恶意合约代码调用脆弱的业务合约，利用合约收款 fallback 特性
    不断的在攻击合约和业务合约重入，直到达到攻击者设定的条件。

    预防方法：
    1) 当给外部地址(很有可能是外部合约地址)转ether时，使用内部方法 transfer()
    因为该方法仅支持(发送) 2300gas 供外部合约调用(如果接收对象是外部合约的话)
    这些 gas 不足以让外部合约再发起一次业务合约的调用(i.e. 重入业务合约)

    2)  checks-effects-interactions 发送ether 之前先改变状态变量

    3) 加锁 额外增加一个状态变量 发送ether 之前改变锁变量状态

### 算术溢出/下溢

    溢出(上溢) uint8 257 --> 1
    下溢 uint 0 - 1 --> 255
    SafeMath

### Unexpected Ether

    selfdestruct(addr_target) 合约销毁后 会把合约账户中的所有ether 发送到 addr_target 如果目标地址是个合约地址，则不会执行该合约中的任何代码(包括 fallback 方法)
    业务合约中在用到 address(this).balance 需要特别注意 因为恶意攻击合约可能会通过
    自我销毁来向我们的业务合约发送ether 这发送过来的ether 对业务合约来说就是未预期的
    ether, 极有可能造成业务逻辑的混乱。

    预防方法：
    使用额外的变量跟踪合约中ether，避免使用address(this).balance
    

