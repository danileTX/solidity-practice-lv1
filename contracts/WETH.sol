// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
*weth合约用于包装eth主币，作为ERC20的合约。标准的ERC20合约包括如下几个功能
*3个查询：
*balanceOf:查询指定地址的Token数量
*allowance:查询指定地址对另一个地址的剩余授权额度
*totalSupply:查询当前合约的Token总量
*2个交易：
*transfer:从当前调用者地址发送指定数量的Token到指定地址，这是一个写入方法，所有还会抛一个Transfer事件
*transferFrom:当向另一个合约地址存款时，对方合约必须调用transferFrom才可以把Token拿到它自己的合约中
*2个事件
*Transfer
*Approval
*1个授权
*approve:授权指定地址可以操作调用者的最大Token数量
*/

contract WETH {
    //state variable
    string public name = 'Wrapped Ether';
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed delegateAds, uint256 amount);
    event Transfer(address indexed src, address indexed toAds, uint256 amount);
    event Deposit(address indexed toAds, uint256 amount);
    event Withdraw(address indexed src, uint256 amount);

    //用户余额映射
    mapping(address => uint256) public balance;
    //一个地址对另一个地址的授权额度
    mapping(address => mapping(address => uint256)) public allowances;
    function deposit() public payable {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withDraw(uint256 amount) public payable{
        require(balance[msg.sender] >= amount);
        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, msg.value);
    }
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }
    function allowance(address giveAddress, address authAddress) public view returns(uint256) {
        return allowances[giveAddress][authAddress];
    }
    function balanceOf(address addr) public view returns (uint256) {
        return balance[addr];
    }

    function approve(address delegateAds, uint256 amount) public returns (bool) {
        allowances[msg.sender][delegateAds] = amount;
        emit Approval(msg.sender, delegateAds, amount);
        return true;
    }
    function transfer(address toAds, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, toAds, amount);
    }
    function transferFrom(address src, address toAds, uint256 amount) public returns (bool) {
        require(balance[src] >= amount);
        if(src != msg.sender) {
            require(allowances[src][msg.sender] >= amount);
            allowances[src][msg.sender] -= amount;
        }
        balance[src] -= amount;
        balance[toAds] += amount;
        emit Transfer(src, toAds, amount);
        return true;
    }
    fallback() external payable {
        deposit();
    }
    receive() external payable {
        deposit();
    }
}
