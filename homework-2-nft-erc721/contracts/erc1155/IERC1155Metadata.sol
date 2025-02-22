// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IERC1155Metadata {
    function uri(uint id) external view returns(string memory);
}
