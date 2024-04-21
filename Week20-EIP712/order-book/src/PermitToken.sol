//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

/// @dev didnt have time to cook orderbook so taken from tommyrharper to understand
contract PermitToken is ERC20Permit {
    constructor(
        string memory _name,
        string memory symbol,
        address _to
    ) ERC20Permit(_name) ERC20(_name, symbol) {
        _mint(_to, 1_000_000 * 10 ** decimals());
    }
}