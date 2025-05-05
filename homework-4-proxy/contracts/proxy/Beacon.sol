// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IBeacon} from "./BeaconProxy.sol";

contract Beacon is IBeacon, Ownable {
    address private impl;

    event Upgraded(address newImplementation);

    constructor(address _implementation) Ownable(msg.sender) {
        impl = _implementation;
    }

    function implementation() external view override returns (address) {
        return impl;
    }

    function upgradeTo(address newImplementation) external onlyOwner {
        impl = newImplementation;
        emit Upgraded(newImplementation);
    }
}
