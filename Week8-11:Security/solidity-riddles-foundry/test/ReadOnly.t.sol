// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {VulnerableDeFiContract, ReadOnlyPool, ReadOnlyPoolAttacker} from "../src/ReadOnly.sol";

contract ReadOnlyTest is Test {
    VulnerableDeFiContract public vulnerableDeFiContract;
    ReadOnlyPool public readOnlyPool;
    ReadOnlyPoolAttacker public readOnlyPoolAttacker;
    address attacker = address(0x1);

    function setUp() public {
        readOnlyPool = new ReadOnlyPool();
        vulnerableDeFiContract = new VulnerableDeFiContract(readOnlyPool);
        readOnlyPoolAttacker = new ReadOnlyPoolAttacker(readOnlyPool, vulnerableDeFiContract);

        readOnlyPool.addLiquidity{value: 100 ether}();
        readOnlyPool.earnProfit{value: 1 ether}();
        vulnerableDeFiContract.snapshotPrice();
        vm.deal(attacker, 2 ether);
    }

    function test_Attack() public {      
        vm.prank(attacker);
        readOnlyPoolAttacker.attack{value: 1 ether}();
        assertEq(vulnerableDeFiContract.lpTokenPrice(), 0);
    }
}