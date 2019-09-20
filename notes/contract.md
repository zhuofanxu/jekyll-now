## 合约基础

### ABI 编码

    硬件存储字节序： 大端字节序(big endian)、小端字节序(little endian)
    大端字节序：高位字节在前，低位字节在后，这是人类读写数值的方法。
    小端字节序：低位字节在前，高位字节在后。

    0x1234567: hex 每位占4bit hex每两位一个字节(不够偶数位的前面补0)
    大端：[0][1]-[2][3]-[4][5]-[6][7]
    小端：[6][7]-[4][5]-[2][3]-[0][1]

    处理器读取外部数据处理方式 必须知道数据的字节序 32位整数 因为它只会按顺序读取字节
    大端字节序
    第一个字节左移 24位(表述后面有3个字节) 后面补0
    第二个字节左移 16位(表述后面有2个字节)
    ...
    最后做或运算(本质就是所有字节做加法运算)
    i = (data[0]<<24) (data[1]<<16) | (data[2]<<8) | (data[3]<<0);

    小端字节序
    第四个字节左移 24位(表述后面有3个字节) 后面补0
    第三个字节左移 16位(表述后面有2个字节)
    ...
    最后做或运算(本质就是所有字节做加法运算)
    i = (data[0]<<0) | (data[1]<<8) | (data[2]<<16) | (data[3]<<24);

    baz(uint32 x, bool y) 调用时需要传给合约编码后的函数签名+参数 总共传输68字节
    ASCII格式的函数签名 sha3后的前4个字节 
    第一个参数，一个被用 0 值字节补充到 32 字节的 uint32 值
    第二个参数，一个被用 0 值字节补充到 32 字节的 boolean 值


### 存储
    存储插槽storage slot 的第一项会以低位对齐（即右对齐）的方式储存
    000000000000000...000000000000034ef1
    000000000000000...000000000000000012
    EVM 每次操作32字节

    使用缩减大小的参数才是有益的。因为编译器会将多个元素打包到一个 存储插槽storage slot 中， 从而将多个读或写合并到一次对存储的操作中。而在处理函数参数或 内存memory 中的值时，因为编译器不会打包这些值，所以没有什么益处。

    所有的复杂类型，即 数组 和 结构 类型，都有一个额外属性，“数据位置”
    函数参数（包括返回的参数）的数据位置默认是 memory， 局部变量的数据位置默认是 storage，状态变量的数据位置强制是 storage （这是显而易见的）。

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

    2)  checks-effects-interactions 发送ether(与其他合约的交互) 之前先改变当前合约的状态变量

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

### tx.origin 鉴别身份 所以应该使用 msg.sendeer 鉴别身份。

    tx.origin 在 re-entrancy 情况下 总是会是业务合约的owner。

    interface TxUserWallet {
        function transferTo(address dest, uint amount) public;
    }

    contract TxAttackWallet {
        address owner;

        function TxAttackWallet() payable public  {
            owner = msg.sender;
        }

        // 这里如果重入成功的话 TxUserWallet(msg.sender) 会被实例化成业务合约实例
        // 因为在这种情况下 msg.sender 是 业务合约的 address. 
        function() payable public {
            TxUserWallet(msg.sender).transferTo(owner, msg.sender.balance);
        }
    }

### 合约通用模式--取回(withdrawal)

    在某个操作中直接发生ether 可能会导致合约直接不可用(核心操作永远失败)
    比如攻击者使用一个fallback 会失败的合约进行攻击业务合约。

### 判断合约调用者是否为非另一个合约

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    这段检测代码存在漏洞：对于已部署成功的合约，由于其地址对应着特定代码，extcodesize 的返回值始终大于 0；然后在构造新合约的过程中（即合约构造方法里）调用游戏参与函数即可绕过该限制，这是因为合约在构造过程中，其地址并未对应任何代码，extcodesize 的返回值为 0

    正确的姿势：
    require(tx.origin == msg.sender, "sorry humans only")
    _;

### 以太坊合约交易Input推函数签名

    合约交易 input 的前四个字节 = sha3(合约函数签名)[0:4] 且不可逆；
    所有在未知函数源代码和abi之前是不可能逆解出函数签名的
    ethescan 是通过自建 4字节sh3(函数签名) 到 函数签名映射数据库做到的