// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DaiToken is ERC20 {
    constructor() public ERC20("mDAI Token", "mDAI") {
        _mint(msg.sender, 1000000000000000000000000);
    }
}
