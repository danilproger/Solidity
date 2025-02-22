// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC1155Receiver} from"./IERC1155Receiver.sol";
import {IERC1155Metadata} from "./IERC1155Metadata.sol";
import {IERC1155} from "./IERC1155.sol";
import {Ownable} from "../util/Ownable.sol";
import {StringUtils} from "../util/StringUtils.sol";

contract ScamMultiToken is IERC1155, IERC1155Metadata, Ownable {
    using StringUtils for uint256;
    mapping(uint256 id => mapping(address owner => uint256 amount)) private _balances;
    mapping(address owner => mapping(address operator => bool approved)) private _operatorApprovals;

    constructor() Ownable(msg.sender) {
    }

    function uri(uint256 id) external pure returns (string memory) {
        return string.concat("https://vaulin.tech/scamnft/", id.toString());
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return _balanceOf(account, id);
    }

    function _balanceOf(address account, uint256 id) internal view returns (uint256) {
        require(account != address(0), "Zero-account balanceOf isn't allowed");
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "Different length for accounts and ids");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(address account, address operator, bool approved) internal {
        require(account != operator, "Self approval isn't allowed");
        _operatorApprovals[account][operator] = approved;
        emit ApprovalForAll(account, operator, approved);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return _isApprovedForAll(account, operator);
    }

    function _isApprovedForAll(address account, address operator) internal view returns (bool) {
        require(account != address(0), "Zero-account isApprovedForAll isn't allowed");
        require(operator != address(0), "Zero-account isApprovedForAll isn't allowed");
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external {
        require(from != address(0), "Zero-account safeTransferFrom isn't allowed");
        require(to != address(0), "Zero-account safeTransferFrom isn't allowed");

        address sender = msg.sender;
        require(_isOwnerOrApproved(from, sender), "You aren't allowed to transfer");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= value, "Low balance");

        _balances[id][from] = fromBalance - value;
        _balances[id][to] += value;

        emit TransferSingle(sender, from, to, id, value);
        require(_checkOnERC1155Received(sender, from, to, id, value, data), "Transfer to non-erc1155 receiver");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external {
        require(from != address(0), "Zero-account safeTransferFrom isn't allowed");
        require(to != address(0), "Zero-account safeTransferFrom isn't allowed");
        require(ids.length == values.length, "Different lengths for ids and values");

        address sender = msg.sender;
        require(_isOwnerOrApproved(from, sender), "You aren't allowed to transfer");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= value, "Low balance");

            _balances[id][from] = fromBalance - value;
            _balances[id][to] += value;
        }

        emit TransferBatch(sender, from, to, ids, values);
        require(_checkOnERC1155BatchReceived(sender, from, to, ids, values, data), "Transfer to non-erc1155 receiver");
    }

    function mint(address to, uint256 id, uint256 value) external onlyOwner {
        require(to != address(0), "Zero-account mint isn't allowed");
        _balances[id][to] += value;
        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values) external onlyOwner {
        require(to != address(0), "Zero-account mint isn't allowed");
        require(ids.length == values.length, "Different lengths for ids and values");

        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][to] += values[i];
        }
        emit TransferBatch(msg.sender, address(0), to, ids, values);
    }

    function burn(address from, uint256 id, uint256 value) external onlyOwner {
        require(from != address(0), "Zero-account burn isn't allowed");
        uint256 balance = _balances[id][from];
        require(balance <= value, "Low balance");
        _balances[id][from] = balance - value;
        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata values) external onlyOwner {
        require(from != address(0), "Zero-account burn isn't allowed");
        require(ids.length == values.length, "Different lengths for ids and values");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 balance = _balances[id][from];
            uint256 value = values[i];

            require(balance <= value, "Low balance");
            _balances[id][from] = balance - value;
        }
        emit TransferBatch(msg.sender, from, address(0), ids, values);
    }

    function _isOwnerOrApproved(address account, address operator) internal view returns (bool) {
        return (
            account == operator ||
            _isApprovedForAll(account, operator)
        );
    }

    function _checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 retval) {
                return retval == IERC1155Receiver.onERC1155Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non-erc1155 receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    function _checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (bytes4 retval) {
                return retval == IERC1155Receiver.onERC1155BatchReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non-erc1155 receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }
}
