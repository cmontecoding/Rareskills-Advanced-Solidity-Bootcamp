// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice ERC20 token used as a reward for staking Royal Apes in StakingSystem.sol
contract StakingToken is Ownable2Step, ERC20 {
    constructor(
        address _stakingSystem
    ) Ownable(_stakingSystem) ERC20("StakingToken", "STKN") {}

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }
}
