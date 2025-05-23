// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MintBurn {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract BridgePolygon is AccessControl {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    IERC20MintBurn public wrappedToken;

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed to, uint256 amount);

    constructor(address _wrappedToken) {
        wrappedToken = IERC20MintBurn(_wrappedToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(RELAYER_ROLE) {
        wrappedToken.mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(uint256 amount) external {
        wrappedToken.burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }
}
