// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ImplV1 {
    uint256 public value;

    function initialize(uint256 _value) external {
        require(value == 0, "Already initialized");
        value = _value;
    }

    function increment() external {
        value += 1;
    }

    function version() external pure returns (string memory) {
        return "V1";
    }
}
