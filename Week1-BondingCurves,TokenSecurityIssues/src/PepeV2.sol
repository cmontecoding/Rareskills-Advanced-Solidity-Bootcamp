// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

///@notice Token with sanctions. Create a fungible token that
/// allows an admin to ban specified addresses from sending and receiving tokens.
contract PepeV2 is Ownable2Step, ERC20 {
    mapping(address => bool) public blacklists;

    constructor(uint256 _totalSupply) Ownable2Step(msg.sender) ERC20("PepeV2", "PEPE") {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }

}
