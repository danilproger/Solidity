// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RoleAccessControl} from "./accesscontrol/RoleAccessControl.sol";
import {MetaTxContext} from "./metatx/MetaTxContext.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC20Permit} from "./permit/ERC20Permit.sol";

contract ScamToken is ERC20, Ownable, RoleAccessControl, MetaTxContext, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        address _trustedForwarder
    )
        ERC20("ScamToken", "SCM")
        Ownable(_msgSender())
        MetaTxContext(_trustedForwarder)
        ERC20Permit("ScamToken", "0.0.1")
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address account, uint256 value) external onlyRole(BURNER_ROLE) {
        _burn(account, value);
    }

    function burn(uint256 value) external onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), value);
    }

    function _msgSender() internal view override(MetaTxContext, Context) returns (address sender) {
        return MetaTxContext._msgSender();
    }

    function _doApprove(address owner, address spender, uint256 amount) internal {
        _approve(owner, spender, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        _permit(owner, spender, value, deadline, v, r, s, _doApprove);
    }
}
