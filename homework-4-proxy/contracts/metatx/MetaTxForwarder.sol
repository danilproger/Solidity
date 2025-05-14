// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract MetaTxForwarder {
    error ForwarderExpiredRequest(uint256 deadline);
    error ForwarderInvalidNonce(uint256 nonce);
    error ForwarderInvalidSign();

    bytes32 private constant EIP_712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 private constant FORWARD_TYPEHASH = keccak256(
        "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint256 deadline,bytes data)"
    );

    bytes32 private _domainSeparator;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        uint256 deadline;
        bytes data;
    }

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

    function domainSeparator() public view returns (bytes32) {
        return _domainSeparator;
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        if (req.deadline < block.timestamp) {
            revert ForwarderExpiredRequest(req.deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                FORWARD_TYPEHASH,
                req.from,
                req.to,
                req.value,
                req.gas,
                req.nonce,
                req.deadline,
                keccak256(req.data)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparator, structHash));
        return recoverSigner(digest, signature) == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature) external payable returns (bool, bytes memory) {
        if (!verify(req, signature)) {
            revert ForwarderInvalidSign();
        }
        if (nonces[req.from] != req.nonce) {
            revert ForwarderInvalidNonce(req.nonce);
        }

        nonces[req.from]++;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        return (success, returndata);
    }

    function recoverSigner(bytes32 digest, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            revert ForwarderInvalidSign();
        }
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return ecrecover(digest, v, r, s);
    }
}
