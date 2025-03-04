// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {Ownable} from "../util/Ownable.sol";

contract ScamToken is IERC20, IERC20Metadata, Ownable {
    /**
     * Имя токена
     */
    string constant public name = "ScamToken1337";
    /**
     * Символ токена
     */
    string constant public symbol = "SCM";

    /**
     * Количество знаков токена
     */
    uint8 constant public decimals = 18;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public totalSupply;

    constructor() Ownable(msg.sender) {
        totalSupply = 1e24;
        balances[msg.sender] = totalSupply;
    }

    /**
     * Баланс токенов кошелька
     */
    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }

    /**
     * Проверить разрешение на использование токенов
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * Перевести токены от отправителя (вызывающий функцию)
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "Balance decrease zero isn't allowed");
        balances[msg.sender] -= value;

        /**
         * Перевод на нулевой адрес == burn
         */
        if (to == address(0)) {
            totalSupply -= value;
        } else {
            balances[to] += value;
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * Перевести токены от отправителя (нужно разрешение)
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _checkAllowance(from, msg.sender, value);

        require(balances[from] >= value, "Balance decrease zero isn't allowed");
        balances[from] -= value;

        /**
         * Перевод на нулевой адрес == burn
         */
        if (to == address(0)) {
            totalSupply -= value;
        } else {
            balances[to] += value;
        }

        emit Transfer(from, to, value);
        return true;
    }

    /**
     * Проверяет допустимое разрешение и уменьшает разрешение на кол-во
     */
    function _checkAllowance(address owner, address spender, uint256 value) internal {
        require(_allowances[owner][spender] >= value, "Allowance decrease zero isn't allowed");
        _allowances[owner][spender] -= value;
        emit Approval(owner, spender, value);
    }

    /**
     * Выдать разрешение на использование токенов
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * Выпустить новые токены (перевести с нулевого адреса)
     */
    function mint(address account, uint256 value) external onlyOwner {
        require(account != address(0), "Mint to Zero address isn't allowed");
        totalSupply += value;
        balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    /**
     * Сжечь токены (перевести на нулевой адрес)
     */
    function burn(address account, uint256 value) external onlyOwner {
        require(account != address(0), "Burn from Zero address isn't allowed");
        require(balances[account] >= value, "Balance decrease zero isn't allowed");
        balances[account] -= value;
        totalSupply -= value;

        emit Transfer(account, address(0), value);
    }
}
