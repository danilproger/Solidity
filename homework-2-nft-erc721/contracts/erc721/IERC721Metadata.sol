// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/**
 * Метадата для контракта ERC721
 */
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}