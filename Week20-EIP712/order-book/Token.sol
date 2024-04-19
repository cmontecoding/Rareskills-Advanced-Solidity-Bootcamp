//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract Token is ERC20Permit {
    constructor(address _to, string memory n) ERC20Permit("MyToken") ERC20("MyToken", "MT") {
        _mint(_to, 1_000_000 * 10 ** decimals());
    }
}