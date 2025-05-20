// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeBSC is AccessControl {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    IERC20 public token;

    event Locked(address indexed to, uint256 amount);
    event Released(address indexed to, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function lock(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        // need approve
        token.transferFrom(msg.sender, address(this), amount);
        emit Locked(msg.sender, amount);
    }

    function release(address to, uint256 amount) external onlyRole(RELAYER_ROLE) {
        token.transfer(to, amount);
        emit Released(to, amount);
    }
}
