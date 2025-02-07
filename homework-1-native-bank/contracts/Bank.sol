// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {INativeBank} from "./NativeBank.sol";

contract Bank is INativeBank {
    address public owner;
    mapping(address => uint256) private accountBalances;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Модификатор, разрешающий выполнение только владельцу контракта
     */
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    function balanceOf(address account) external view override returns (uint256) {
        return accountBalances[account];
    }

    function deposit() public payable override {
        require(msg.value > 0, "Zero deposit isn't allowed");

        accountBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override {
        if (amount == 0) {
            revert WithdrawalAmountZero(msg.sender);
        }
        uint256 balance = accountBalances[msg.sender];
        if (balance < amount) {
            revert WithdrawalAmountExceedsBalance(msg.sender, amount, balance);
        }
        accountBalances[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 selfBalance = address(this).balance;
        require(selfBalance > 0, "No money in native bank");

        (bool sent,) = payable(owner).call{value: selfBalance}("");
        require(sent, "withdrawAll failed");
        emit Withdrawal(msg.sender, selfBalance);
    }
}