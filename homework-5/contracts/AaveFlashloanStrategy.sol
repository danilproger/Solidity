// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract SimpleDEX {
    address public tokenA;
    address public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    constructor(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB) {
        tokenA = _tokenA;
        tokenB = _tokenB;

        reserveA = _amountA;
        reserveB = _amountB;
    }

    // A → B
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Invalid input");

        uint256 amountBOut = getAmountOutAtoB(amountAIn);
        require(amountBOut <= reserveB, "Not enough B");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;
    }

    // B → A
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Invalid input");

        uint256 amountAOut = getAmountOutBtoA(amountBIn);
        require(amountAOut <= reserveA, "Not enough A");

        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;
    }

    // Смещённый курс A → B (1 A = 2 B)
    function getAmountOutAtoB(uint256 amountAIn) public pure returns (uint256) {
        return amountAIn * 2;
    }

    // Смещённый курс B → A (1 B = 0.25 A) — хуже, чем обратный
    function getAmountOutBtoA(uint256 amountBIn) public pure returns (uint256) {
        return amountBIn / 4;
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }
}
