// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {FlashLoanSimpleReceiverBase, IPoolAddressesProvider} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface SimpleDEX {
    function tokenA() external view returns (address);
    function tokenB() external view returns (address);
    function swapAforB(uint256 amountAIn) external;
    function swapBforA(uint256 amountBIn) external;
}

contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase, Ownable  {
    SimpleDEX public dex;

    constructor(address _provider, address _dex) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_provider)) Ownable(msg.sender) {
        dex = SimpleDEX(_dex);
    }

    // Запросить flash loan
    function requestFlashLoan(address asset, uint256 amount) external onlyOwner {
        POOL.flashLoanSimple(
            address(this),
            asset,
            amount,
            "",
            0
        );
    }

    // Выполнить арбитражную операцию
    function executeOperation(
        address asset, // tokenA
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(POOL), "Only pool can call");

        address tokenA = asset;
        address tokenB = dex.tokenB();

        IERC20(tokenA).approve(address(dex), amount);

        // Обменять весь A → B
        dex.swapAforB(amount);

        uint256 totalOwed = amount + premium;

        // Рассчитать, сколько B нужно для обратного выкупа A
        uint256 requiredB = totalOwed * 4; // т.к. 1 B = 0.25 A → A = B / 4

        // Проверка, достаточно ли у нас B
        uint256 tokenBBalance = IERC20(tokenB).balanceOf(address(this));
        require(tokenBBalance >= requiredB, "Not enough B to buy back A");

        // Обменять часть B обратно на A
        IERC20(tokenB).approve(address(dex), requiredB);
        dex.swapBforA(requiredB);

        // Возврат flash loan с премией
        IERC20(tokenA).approve(address(POOL), totalOwed);

        return true;
    }

    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        IERC20(token).transfer(owner(), balance);
    }
}