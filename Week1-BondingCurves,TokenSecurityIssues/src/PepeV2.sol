// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

///@notice Token with sanctions. Create a fungible token that
/// allows an admin to ban specified addresses from sending and receiving tokens.
contract PepeV2 is Ownable, ERC20 {
    mapping(address => bool) public blacklists;

    constructor(
        uint256 _totalSupply
    ) Ownable(msg.sender) ERC20("PepeV2", "PEPE") {
        _mint(msg.sender, _totalSupply);
    }

    /// @notice Blacklist an address
    function blacklist(
        address _address,
        bool _isBlacklisted
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisted;
    }

    /// @notice Overide _update to check if the sender or receiver is blacklisted
    /// before completing any transfer
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _beforeTokenTransfer(from, to);
        super._update(from, to, amount);
    }

    /// @notice Check if the sender or receiver is blacklisted
    function _beforeTokenTransfer(address from, address to) internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}
