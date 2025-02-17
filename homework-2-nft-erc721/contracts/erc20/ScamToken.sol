// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {Ownable} from "../util/Ownable.sol";

contract ScamToken is IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() Ownable(msg.sender) {
        _totalSupply = 1e24;
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * Имя токена
     */
    function name() external pure returns (string memory) {
        return "ScamToken1337";
    }

    /**
     * Символ токена
     */
    function symbol() external pure returns (string memory) {
        return "SCM";
    }

    /**
     * Количество знаков токена
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /**
     * Общее количество токенов
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * Баланс токенов кошелька
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
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
        require(to != address(0), "Transfer to Zero address isn't allowed");
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * Перевести токены от отправителя (нужно разрешение)
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0), "Transfer from Zero address isn't allowed");
        require(to != address(0), "Transfer to Zero address isn't allowed");
        _checkAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * Проверяет допустимое разрешение и уменьшает разрешение на кол-во
     */
    function _checkAllowance(address owner, address spender, uint256 value) internal {
        uint256 currAllowance = this.allowance(owner, spender);
        require(currAllowance >= value, "Allowance decrease zero isn't allowed");
        _approve(owner, spender, currAllowance - value);
    }

    /**
     * Выдать разрешение на использование токенов
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Spender Zero address isn't allowed in approve");
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    /**
     * Внутренняя функция на разрешение использования токенов
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "Owner Zero address isn't allowed in approve");
        require(spender != address(0), "Owner Zero address isn't allowed in approve");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * Выпустить новые токены (перевести с нулевого адреса)
     */
    function mint(address account, uint256 value) external onlyOwner {
        require(account != address(0), "Mint to Zero address isn't allowed");
        _transfer(address(0), account, value);
    }

    /**
     * Сжечь токены (перевести на нулевой адрес)
     */
    function burn(address account, uint256 value) external onlyOwner {
        require(account != address(0), "Burn from Zero address isn't allowed");
        _transfer(account, address(0), value);
    }

    /**
     * Внутренняя функция перевода токенов
     */
    function _transfer(address from, address to, uint256 value) internal  {
        require(from != address(0) && to != address(0), "Transfer from Zero to Zero addresses isn't allowed");

        /**
         * Перевод с нулевого адреса == mint
         */
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            require(fromBalance >= value, "Balance decrease zero isn't allowed");
            _balances[from] = fromBalance - value;
        }
        /**
         * Перевод на нулевой адрес == burn
         */
        if (to == address(0)) {
            _totalSupply -= value;
        } else {
            _balances[to] = _balances[to] + value;
        }

        emit Transfer(from, to, value);
    }
}
