// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IBeacon.sol";

contract BeaconProxy {
    address public immutable beacon;

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function _getImplementation() private view returns (address) {
        return IBeacon(beacon).implementation();
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() private {
        address impl = _getImplementation();
        require(impl != address(0), "No impl");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
