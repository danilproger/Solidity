// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./IERC721Metadata.sol";
import {IERC721} from "./IERC721.sol";
import {Ownable} from "../util/Ownable.sol";
import {StringUtils} from "../util/StringUtils.sol";

contract ScamNFT is IERC721, IERC721Metadata, Ownable {
    using StringUtils for uint256;
    mapping(uint256 tokenId => address owner) private _tokenOwners;
    mapping(address owner => uint256 balance) private _balances;
    mapping(uint256 tokenId => address approved) private _allowances;
    mapping(address owner => mapping(address operator => bool approved)) private _operatorApprovals;

    constructor() Ownable(msg.sender) {

    }

    function name() external pure returns (string memory) {
        return "ScamNFT1337";
    }

    function symbol() external pure returns (string memory) {
        return "SCM";
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);
        return string.concat("https://vaulin.tech/scamnft/", tokenId.toString());
    }

    /**
     * Количество токенов на балансе
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address isn't allowed in balanceOf");
        return _balances[owner];
    }

    /**
     * Владелец токена
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownerOf(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return _requireMinted(tokenId);
    }

    /**
     * Разрешение на использование токена
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _getApproved(tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        _requireMinted(tokenId);
        return _allowances[tokenId];
    }

    /**
     * Разрешение на использование всех токенов
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * Выдать/отозвать разрешение на использование токена
     */
    function approve(address approved, uint256 tokenId) external {
        address owner = _requireMinted(tokenId);
        require(approved != owner, "Self-approve isn't allowed");
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "You aren't allowed approve this token");

        _allowances[tokenId] = approved;

        emit Approval(msg.sender, approved, tokenId);
    }

    /**
     * Выдать/отозвать разрешение на использование всех токенов
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "Zero-approve isn't allowed");
        require(operator != msg.sender, "Self-approve isn't allowed");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * Выпустить новый токен на адрес
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        require(to != address(0), "Zero address to mint isn't allowed");
        require(_tokenOwners[tokenId] == address(0), "Token was already minted");

        _tokenOwners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * Сжечь токен (разрешено владельцу либо есть разрешение)
     */
    function burn(uint256 tokenId) external {
        address owner = _requireMinted(tokenId);
        bool isAllowedAction = _isOwnerOrApproved(msg.sender, tokenId);

        require(isAllowedAction, "You aren't allowed to burn this token");

        _tokenOwners[tokenId] = address(0);
        _balances[owner] -= 1;

        emit Transfer(owner, address(0), tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(from != address(0), "Zero-transfer from isn't allowed");
        require(to != address(0), "Zero-transfer to isn't allowed");

        address owner = _requireMinted(tokenId);
        require(owner == from, "Transfer from not owner isn't allowed");
        bool isAllowedAction = _isOwnerOrApproved(msg.sender, tokenId);

        require(isAllowedAction, "You aren't allowed to transfer this token");
        _tokenOwners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        _transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "Transfer to non-erc721 receiver"
        );
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        _transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, ""),
            "Transfer to non-erc721 receiver"
        );
    }

    function _isOwnerOrApproved(address operator, uint tokenId) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            operator == owner ||
            _isApprovedForAll(owner, operator) ||
            _getApproved(tokenId) == operator
        );
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non-erc721 receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    function _requireMinted(uint256 tokenId) internal view returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "Token wasn't minted");
        return owner;
    }
}
