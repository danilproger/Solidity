# Smart Contract Audit Report: FlashLoanArbitrage

**Contract Name**: `FlashLoanArbitrage`  
**Audit Date**: 2025-05-26  
**Language**: Solidity  
**Compiler Version**: ^0.8.28  
**Dependencies**:
- Aave V3 (`FlashLoanSimpleReceiverBase`, `IPoolAddressesProvider`)
- OpenZeppelin (`Ownable`, `IERC20`)
- Custom (`SimpleDEX`)

---

## Summary

| Category             | Issues |
|----------------------|--------|
| Critical             | 2      |
| High                 | 2      |
| Medium               | 1      |
| Low/Gas Optimization | 4      |
| Informational        | 2      |

---

## Critical Issues

### 1. Hardcoded Swap Rate Assumption

- **Issue**: The contract assumes a fixed exchange rate `1 B = 0.25 A`.
- **Impact**: If `SimpleDEX` is price-variable or manipulated (which is likely), the `requiredB = totalOwed * 4` becomes inaccurate.
- **Recommendation**: Query the actual swap rate dynamically or calculate the required B using real-time return from `dex.getExpectedReturn()` if available.

### 2. No Slippage or Arbitrage Profit Check

- **Issue**: The contract doesn't verify whether the arbitrage operation is actually profitable.
- **Impact**: May execute flash loan and pay fees without any real profit, leading to loss.
- **Recommendation**: Add logic to check that `IERC20(tokenA).balanceOf(this) > amount + premium` before repaying the loan.

---

## High Severity Issues

### 3. Arbitrary Flash Loan Asset and Amount

- **Issue**: The `requestFlashLoan` function allows the `owner` to initiate a flash loan with any asset and any amount.
- **Impact**: In case of misconfiguration or compromised ownership, the contract can be used to borrow arbitrary amounts and cause losses or failed operations.
- **Recommendation**: Add validation for `asset` and `amount` (e.g., whitelisting assets, access controls, setting max loan amounts).

### 4. Susceptibility to Sandwich Attacks

- **Issue**: No use of private transactions or MEV protection.
- **Impact**: Arbitrage logic is fully visible on-chain, attackers can sandwich the swap calls to exploit price movements.
- **Recommendation**: Consider integrating with MEV-protected relayers (e.g., Flashbots) or batching swaps atomically.

---

## Medium Severity Issues

### 5. No Reentrancy Guard on Withdraw

- **Issue**: `withdrawProfits` allows token transfers with no `nonReentrant` modifier.
- **Impact**: Reentrancy is unlikely but still theoretically possible depending on ERC20 implementation.
- **Recommendation**: Use `ReentrancyGuard` or similar pattern.

---

## Gas Optimization

### 6. Combine Multiple Approve Calls

- **Issue**: Each `approve` call sets allowance again.
- **Recommendation**: Use `safeIncreaseAllowance` or cache allowance if re-used.

### 7. Avoid Redundant Interface Calls

- **Example**: `IERC20(tokenB).balanceOf(address(this))` is used even though we just swapped.
- **Recommendation**: Cache result if used repeatedly.

### 8. Inline token addresses

- **Recommendation**: Cache `tokenA` and `tokenB` at the start of the function and reuse.

### 9. Empty bytes in `flashLoanSimple`

- **Suggestion**: Avoid passing `""` if unused; use optional calldata.

---

## Informational

### 10. Missing Events

- **Issue**: No events are emitted for key actions (`flashLoan`, `withdrawProfits`).
- **Recommendation**: Add events for traceability and monitoring.

### 11. No Profit Verification

- **Recommendation**: Log or assert that the arbitrage returned more than initial borrowed + fee.

---

## Suggested Code Improvements

- Add `ReentrancyGuard` to `withdrawProfits`
- Emit events: `FlashLoanRequested`, `ProfitWithdrawn`, `ArbitrageExecuted`
- Replace fixed-rate logic with dynamic pricing

---

## Conclusion

The contract is functional but includes assumptions about exchange rates and lacks protections for slippage, MEV, and proper event logging. Improvements are needed for production-readiness.
