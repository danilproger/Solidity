// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract ERC20Permit {
    error ForwarderExpiredRequest(uint256 deadline);
    error ForwarderInvalidSign();

    bytes32 private constant EIP_712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    bytes32 private _domainSeparator;

    mapping(address => uint256) public nonces;

    constructor(
        string memory name,
        string memory version
    ) {
        _domainSeparator = keccak256(
            abi.encode(
                EIP_712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        function(address, address, uint256) internal _approveFunc
    ) internal {
        if (deadline < block.timestamp) {
            revert ForwarderExpiredRequest(deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparator, structHash));

        address signer = ecrecover(digest, v, r, s);
        if (signer != owner) {
            revert ForwarderInvalidSign();
        }

        _approveFunc(owner, spender, value);
    }
}
