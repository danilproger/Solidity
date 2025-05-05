// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ImplV2 {
    uint256 public value;

    function initialize(uint256 _value) external {
        require(value == 0, "Already initialized");
        value = _value;
    }

    function increment() external {
        value += 15;
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}
