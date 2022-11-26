// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../util/ERC20.sol";

contract TestToken is ERC20 {

    constructor() ERC20("test", "test") {
        _mint(msg.sender, 1e20);
    }
}
