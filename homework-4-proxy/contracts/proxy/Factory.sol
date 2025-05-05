// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./BeaconProxy.sol";

contract Factory {
    address public beacon;
    address[] public allProxies;

    event ProxyCreated(address proxy);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function create() external returns (address proxy) {
        proxy = address(new BeaconProxy(beacon));
        allProxies.push(proxy);
        emit ProxyCreated(proxy);
    }

    function getAll() external view returns (address[] memory) {
        return allProxies;
    }
}
