pragma solidity >=0.4.25 <0.6.0;

contract ERC20Token {
    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function transfer(address to, uint value) public returns (bool);
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address payable public owner;
    mapping(address => bool) managers;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract creator can call this method");
        _;
    }
    modifier onlyManager() {
        require(managers[msg.sender] || msg.sender == owner, "Only contract manager can call this method");
        _;
    }
}

contract ISOBasic is Ownable {

    // 记录共振参与事件
    /*
    * tokenAddr: 项目代币合约地址
    * joiner: 参与者账户地址
    * inviter: 邀请人地址
    * inValue: 参与者打入的募集币数量(这里指ETH)
    * outValue: 参与者获得的共振币数量(这里指项目方的代币)
    * period: 参与的ISO轮次/期数
    * blockNumber: 参与交易被打包的块高
    */
    event JoinISOEvent(address tokenAddr, address joiner, address inviter, uint inValue, uint outValue, uint32 period, uint blockNumber);
    event sentRewardEvent(uint totalAddress, uint totalValue, uint32 period);

    uint constant WEIS = 10 ** 18;

    struct Token {
        // 代币精度
        uint32 decimals;
        // 初始兑换倍数
        uint32 initRatio;
        // ISO 每轮募集目标
        uint periodGoal;
        // ISO 总募集数
        uint totalGoal;
        // ISO 已达目标数
        uint totalReached;
        // ISO 已共振币数量
        uint sentAmount;
        // ISO 衰减因子 因为合约内不支持浮点数 用整数和精度模拟
        uint decayFactor;
        // ISO 衰减因子二
        uint decayFactorR;
        // ISO 衰减因子精度
        uint32 decayDecimals;
        // 当前进行的轮次/期数
        uint32 currentPeriod;
        // 当前轮次募集数
        uint currentReached;
        // 是否完成ISO目标
        bool complete;
        // 是否取出募集资金
        bool hasTook;
        // 每轮项目方提取百分点
        uint32 projectPercent;
        // 每轮owner提取百分点
        uint32 ownerPercent;
        // 活动开始时间戳 秒计
        uint startTimestamp;
        // 项目方自动领取地址
        address payable projectAddr;
        // 项目方取款地址
        address payable takeAddr;
        // 平台方自动领取地址
        address payable ownerAddr;
        // 限购规则
        uint[3][] rules;
        // 最低投入数量 测试网 10 ** 16 主网：4 * (10 ** 16）
        uint minValue;
        // 每轮奖励发放记录
        mapping(uint => bool) rewards;
    }
}

contract ISOMarket is ISOBasic {

    using SafeMath for uint;

    mapping(address => Token) tokens;

    // 测试根据轮次返回系数、比例 outDecimalsRatio带上代币精度
    function getPeriodInfo(address tokenAddr, uint32 period)
    public
    view
    returns (uint, uint) {
        Token memory token = tokens[tokenAddr];
        uint r = token.decayFactor;
        uint R = token.decayFactorR;
        uint32 p = period;
        uint zoom = 10 ** uint(token.decayDecimals);
        uint M = R*zoom + r*r*(p*p - p) + r*R*(p - 1);
        uint ratio = R.mul(zoom).mul(10 ** uint(token.decimals)).div(M);
        uint outDecimalsRatio = uint(token.initRatio).mul(10 ** uint(token.decimals)).mul(R*zoom).div(M);
        return (ratio, outDecimalsRatio);
    }

    // 获取项目信息
    function getTokenInfo(address tokenAddr) public view
    returns (uint, uint, uint, uint, uint, uint, uint, uint, bool) {
        Token memory token = tokens[tokenAddr];
        ERC20Token tokenContract = ERC20Token(tokenAddr);
        uint leftAmount = tokenContract.balanceOf(address(this));
        return (
                token.totalGoal,
                token.periodGoal,
                token.totalReached,
                leftAmount,
                token.sentAmount,
                token.currentPeriod,
                token.currentReached,
                address(this).balance,
                token.complete
        );
    }
    
    // 获取项目限购规则
    function getTokenRule(address tokenAddr) public view
    returns (uint[3][] memory) {
        Token memory token = tokens[tokenAddr];
        return token.rules;
    }

    // 判断参与金额是否符合限购规则
    function checkValueRule(address tokenAddr, uint value, uint period)
    public
    view
    returns (bool) {
        bool result = false;
        Token memory token = tokens[tokenAddr];
        for (uint i = 0; i < token.rules.length; i++) {
            uint[3] memory rule = token.rules[i];
            if (rule[0] <= period && period <= rule[1]) {
                if (value <= rule[2]) {
                    result = true;
                }
                break;
            }
        }
        return result;
    }

    // 设置合约管理员
    function setManager(address[] memory addrs, bool option) public onlyOwner{
        for (uint16 index = 0; index < addrs.length; index++) {
            managers[addrs[index]] = option;
        }
    }

    // ETH取款
    function takeBalance(address tokenAddr, uint value) public onlyOwner {
        // Token storage token = tokens[tokenAddr];
        // require(token.complete, "The ISO project not exist or not finished");
        // require(!token.hasTook, "The ISO project balance has been took aleady");
        // token.hasTook = true;
        // msg.sender.transfer(token.totalGoal);
        // 直接提出合约所有余额
        Token memory token = tokens[tokenAddr];
        token.takeAddr.transfer(value);
    }

    // ERC20取款
    function takeERC20Balance(address tokenAddr) public onlyOwner {
        ERC20Token tokenContract = ERC20Token(tokenAddr);
        Token memory token = tokens[tokenAddr];
        tokenContract.transfer(token.takeAddr, tokenContract.balanceOf(address(this)));
    }

    // 发放奖励
    function sendReward(address tokenAddr, address payable[] memory addrs, uint[] memory vals, uint32 period) public onlyManager {
        Token storage token = tokens[tokenAddr];
        require(token.currentPeriod > period, "The period iso not finished");
        require(!token.rewards[period], "The period has rewarded");
        uint totalValue = 0;
        for (uint16 index = 0; index < addrs.length; index++) {
            addrs[index].transfer(vals[index]);
            totalValue = totalValue.add(vals[index]);
        }
        token.rewards[period] = true;
        emit sentRewardEvent(addrs.length, totalValue, period);
    }

    //注册活动
    function registerToken(
        address tokenAddr, uint32 decimals,
        uint32 initRatio, uint totalGoal, uint periodGoal,
        uint decayFactor, uint decayFactorR, uint32 decayDecimals,
        address payable projectAddr, address payable takeAddr,
        uint startTimestamp, uint[3][] memory rules
    )public
    onlyOwner {
        Token memory token = tokens[tokenAddr];
        require(token.decimals == 0, "Token has aleady exist");
        tokens[tokenAddr] = Token({
            decimals: decimals,
            initRatio: initRatio,
            periodGoal: periodGoal,
            totalGoal: totalGoal,
            // periodGoal: periodGoal.mul(WEIS),
            // totalGoal: totalGoal.mul(WEIS),
            totalReached: 0,
            sentAmount: 0,
            decayFactor: decayFactor,
            decayFactorR: decayFactorR,
            decayDecimals: decayDecimals,
            currentReached: 0,
            currentPeriod: 1,
            complete: false,
            hasTook: false,
            projectPercent: 25,
            ownerPercent: 5,
            startTimestamp: startTimestamp,
            projectAddr: projectAddr,
            takeAddr: takeAddr,
            ownerAddr: owner,
            minValue: 100000000000000000,
            rules: rules
        });
    }

    // 计算每轮项目方提取
    function _getValPeriodProjectTake(Token memory token)
    private
    pure
    returns (uint) {
        return (token.periodGoal * token.projectPercent).div(100);
    }
    // 计算每轮owner提取
    function _getValPeriodOwnerTake(Token memory token)
    private
    pure
    returns (uint) {
        return (token.periodGoal * token.ownerPercent).div(100);
    }
    // 内部函数 获取outAmount
    // 计算公式 1/(1 + (p-1)r) 先转化成相应的整数计算 返回代币精度化的结果
    function _getDecimalsRatio(uint32 decimals, uint32 initRatio, uint r, uint R, uint32 ds, uint32 p)
    private
    pure
    returns (uint)
    {
        uint zoom = 10 ** uint(ds);
        uint M = R*zoom + r*r*(p*p - p) + r*R*(p - 1);
        // uint ratio = R.mul(10 ** decimals).div(M);
        uint outDecimalsRatio = uint(initRatio).mul(10 ** uint(decimals)).mul(R*zoom).div(M);
        // uint ratio = (10 ** uint(decayDecimals * 2)).div(10 ** uint(decayDecimals) + uint(decayFactor) * (period - 1));
        // uint outDecimalsRatio = uint(initRatio).mul(ratio).mul(10 ** uint(decimals)).div(10 ** uint(decayDecimals));
        return outDecimalsRatio;
    }

    // 判断当前阶段参与金额是否符合限购规则
    function _checkValueRule(Token memory token, uint value)
    private
    pure
    returns (bool) {
        bool result = false;
        for (uint i = 0; i < token.rules.length; i++) {
            uint[3] memory rule = token.rules[i];
            if (rule[0] <= token.currentPeriod && token.currentPeriod <= rule[1]) {
                if (value <= rule[2]) {
                    result = true;
                }
                break;
            }
        }
        return result;
    }
    // 更新项目状态
    function _updateToken(Token storage token, uint inValue, uint outAmount, uint outDecimalsRatio)
    private
    returns (uint[3] memory){
        uint refund = 0;
        uint realInValue = inValue;
        uint realOutAmount = outAmount;
        uint previewSum = inValue.add(token.currentReached);
        if (previewSum > token.periodGoal) {
            refund = previewSum - token.periodGoal;
            realInValue = token.periodGoal - token.currentReached;
            // 这里realInValue的值如果太小, 对于精度小于 18 的代币 realOutAmount 很有可能超出精度 得到0的结果
            realOutAmount = outDecimalsRatio.mul(realInValue).div(WEIS);
            token.totalReached = realInValue.add(token.totalReached);
            token.sentAmount = realOutAmount.add(token.sentAmount);
            token.currentPeriod += 1;
            token.currentReached = 0;
        } else if (previewSum == token.periodGoal) {
            token.totalReached = inValue.add(token.totalReached);
            token.sentAmount = outAmount.add(token.sentAmount);
            token.currentPeriod += 1;
            token.currentReached = 0;
        }
        else {
            token.totalReached = inValue.add(token.totalReached);
            token.sentAmount = outAmount.add(token.sentAmount);
            token.currentReached = inValue.add(token.currentReached);
        }
        // ISO项目完成目标、ISO结束
        if (token.totalReached == token.totalGoal) {
            token.complete = true;
        }
        return [refund, realInValue, realOutAmount];
    }
    // 参与活动
    function joinISO(address tokenAddr, address inviter) public payable {
        Token storage token = tokens[tokenAddr];

        require(token.decimals > 0, "The iso project not exist");
        require(now >= token.startTimestamp, "The iso project not start");
        require(!token.complete, "The iso project has completed");
        require(msg.value >= token.minValue, "Accept min ether less than minValue");
        ERC20Token tokenContract = ERC20Token(tokenAddr);
        require(tokenContract.balanceOf(address(this)) > 0, "The contract has no erc20 token balance");

        uint32 curPeriod = token.currentPeriod;
        address _inviter = inviter;

        // 验证推荐地址 不能是自己
        if (_inviter == msg.sender) {
            _inviter = address(0);
        }

        // 限购规则判断 不符合直接退款
        bool isCorrect = _checkValueRule(token, msg.value);
        if (!isCorrect) {
            msg.sender.transfer(msg.value);
            return;
        }

        // 计算每轮兑换比例、数量
        uint outDecimalsRatio = _getDecimalsRatio(
            token.decimals, token.initRatio, token.decayFactor,
            token.decayFactorR, token.decayDecimals, curPeriod
        );
        uint outAmount = outDecimalsRatio.mul(msg.value).div(WEIS);

        // 更新token状态
        uint[3] memory result = _updateToken(token, msg.value, outAmount, outDecimalsRatio);

        emit JoinISOEvent(tokenAddr, msg.sender, _inviter, result[1], result[2], curPeriod, block.number);
        tokenContract.transfer(msg.sender, result[2]);

        // 超过每轮目标部分退款
        if (result[0] > 0) {
            msg.sender.transfer(result[0]);
        }

        // 每轮结束时 项目方、平台方提取部分款
        if (token.currentPeriod > curPeriod) {
            token.projectAddr.transfer(_getValPeriodProjectTake(token));
            token.ownerAddr.transfer(_getValPeriodOwnerTake(token));
        }
    }
}