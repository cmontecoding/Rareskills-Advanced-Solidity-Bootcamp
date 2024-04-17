//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Token is ERC20Permit {
    constructor(address _to) ERC20Permit("MyToken") ERC20("MyToken", "MT") {
        _mint(0x3d18f89407b2298B6352F748ab36cc40Ed9F002f, 1_000_000 * 10 ** decimals());
    }
}