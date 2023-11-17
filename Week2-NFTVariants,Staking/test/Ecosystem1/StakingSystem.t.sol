// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {StakingSystem, RoyalApes, StakingToken} from "../../src/Ecosystem1/StakingSystem.sol";

contract StakingSystemTest is Test {
    StakingSystem stakingSystem;
    RoyalApes royalApes;
    StakingToken stakingToken;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        /// @dev this is so lastClaimedTime is not 0
        vm.warp(block.timestamp + 1 days);

        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        vm.deal(user1, 10 ether);

        royalApes = new RoyalApes(address(this), bytes32(0));
        stakingToken = new StakingToken(address(this));
        stakingSystem = new StakingSystem(
            address(royalApes),
            address(stakingToken)
        );

        /// @dev transfer owner of StakingToken to StakingSystem
        stakingToken.transferOwnership(address(stakingSystem));
        assertTrue(stakingToken.owner() == address(stakingSystem));
    }

    function testStake() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);

        assertTrue(stakingSystem.isStaked(user1));
        assertTrue(stakingSystem.stakedApeOwner(1) == user1);
        assertTrue(stakingSystem.lastClaimedTime(user1) == block.timestamp);
        assertTrue(royalApes.ownerOf(1) == address(stakingSystem));
    }

    function testStakeAlreadyStaked() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);
        royalApes.approve(address(stakingSystem), 2);
        vm.expectRevert("You already have a staked Ape");
        stakingSystem.stake(2);
    }

    function testUnstake() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);
        stakingSystem.unstake(1);

        assertTrue(stakingSystem.isStaked(user1) == false);
        assertTrue(stakingSystem.stakedApeOwner(1) == address(0));
        assertTrue(stakingSystem.lastClaimedTime(user1) == 0);
        assertTrue(royalApes.ownerOf(1) == user1);
    }

    function testWithdrawTokens() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);
        vm.warp(block.timestamp + 1 days);
        stakingSystem.withdrawTokens();
        assertTrue(stakingToken.balanceOf(user1) == 10);
    }

    function testWithdrawTokensTooSoon() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);
        vm.warp(block.timestamp + 1 days - 1);
        vm.expectRevert("You cannot claim yet");
        stakingSystem.withdrawTokens();
    }

    function testWithdrawCannotWithdrawImmediatelyAfterWithdraw() public {
        vm.startPrank(user1);
        royalApes.mint{value: 1 ether}();
        royalApes.approve(address(stakingSystem), 1);
        stakingSystem.stake(1);
        vm.warp(block.timestamp + 1 days);
        stakingSystem.withdrawTokens();
        assertTrue(stakingToken.balanceOf(user1) == 10);
        vm.expectRevert("You cannot claim yet");
        stakingSystem.withdrawTokens();
    }
}
