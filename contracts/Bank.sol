// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Bank {
    address public immutable owner;
    // 存储用户存款的映射
    mapping(address => mapping(address => uint256)) public deposits;
    mapping(address => mapping(address => uint256[])) public depositsERC721;


    event Deposit(address _ads, uint256 amount);
    event Withdraw(uint256 amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        // emit Withdraw(address(this).balance);
        // selfdestruct(payable(msg.sender));

        // transfer all funds from this contract back to the owner
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 拓展
    // ERC20
    // 存款函数
    function depositERC20Token(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // 调用 ERC-20 代币合约的 transferFrom 函数
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        // 更新存款映射
        deposits[msg.sender][token] += amount;
    }

    // 提取函数
    function withdrawERC20(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(deposits[msg.sender][token] >= amount, "Insufficient balance");

        // 更新存款映射
        deposits[msg.sender][token] -= amount;

        // 调用 ERC-20 代币合约的 transfer 函数
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }

    // 存款函数
    function depositERC721(address token, uint256 tokenId) external {
        // 调用 ERC-721 代币合约的 transferFrom 函数
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);

        // 更新存款映射
        depositsERC721[msg.sender][token].push(tokenId);
    }

    // 提取函数
    function withdrawERC721(address token, uint256 tokenId) external {
        // 检查用户是否存入该 tokenId
        uint256[] storage userTokens = depositsERC721[msg.sender][token];
        bool found = false;
        uint256 index = 0;

        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                found = true;
                index = i;
                break;
            }
        }

        require(found, "Token not deposited");

        // 移除 tokenId
        userTokens[index] = userTokens[userTokens.length - 1];
        userTokens.pop();

        // 调用 ERC-721 代币合约的 transfer 函数
        IERC721(token).transferFrom(address(this), msg.sender, tokenId);
    }
}
