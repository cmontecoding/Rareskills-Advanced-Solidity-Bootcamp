// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

///@notice Token with god mode. A special address is able
/// to transfer tokens between addresses at will.
contract GodToken is Ownable2Step, ERC20 {
    constructor(
        uint256 _totalSupply
    ) Ownable(msg.sender) ERC20("GodToken", "GODT") {
        _mint(msg.sender, _totalSupply);
    }

    /// @notice Owner can transfer tokens between addresses
    function godTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transfer(_from, _to, _amount);
    }
}
