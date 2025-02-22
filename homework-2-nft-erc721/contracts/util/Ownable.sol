// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Ownable {
    address private _owner;

    /**
     * Модификатор, разрешающий выполнение только владельцу контракта
     */
    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner allowed run this function");
        _;
    }

    constructor(address owner){
        _owner = owner;
    }
}
