// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract MetaTxContext {
    address public trustedForwarder;

    constructor(address _trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) internal view returns (bool) {
        return forwarder == trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
