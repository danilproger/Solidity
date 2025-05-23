// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ScamToken is ERC20 {
    constructor() ERC20("ScamToken", "SCM") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
