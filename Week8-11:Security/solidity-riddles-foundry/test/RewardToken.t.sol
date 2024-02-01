// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {RewardToken, NftToStake, Depositoor, DepositoorAttack} from "../src/RewardToken.sol";

contract RewardTokenTest is Test {
    NftToStake public nft;
    RewardToken public rewardToken;
    Depositoor public depositoor;
    DepositoorAttack public attacker;
    address public attackerWallet;

    function setUp() public {
        attackerWallet = address(0x1);
        nft = new NftToStake(attackerWallet);
        depositoor = new Depositoor(nft);
        rewardToken = new RewardToken(address(depositoor));
        depositoor.setRewardToken(rewardToken);
        attacker = new DepositoorAttack(
            address(attackerWallet),
            address(nft),
            address(depositoor),
            address(rewardToken)
        );
        vm.prank(attackerWallet);
        nft.transferFrom(attackerWallet, address(attacker), 42);


        assertEq(nft.ownerOf(42), address(attacker));
        assertEq(rewardToken.balanceOf(address(depositoor)), 100e18);
        assertEq(address(depositoor.rewardToken()), address(rewardToken));
    }

    function test_Attack() public {      
        attacker.stake();
        vm.warp(block.timestamp + 5.1 days);
        attacker.attack();
        assertEq(rewardToken.balanceOf(address(attacker)), 100e18);
        assertEq(rewardToken.balanceOf(address(depositoor)), 0);
    }
}