// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IBeacon {
    function implementation() external view returns (address);
}
