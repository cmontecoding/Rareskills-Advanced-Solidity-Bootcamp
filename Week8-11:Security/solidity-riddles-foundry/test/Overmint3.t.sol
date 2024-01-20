// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Overmint3, Overmint3Attack} from "../src/Overmint3.sol";

contract Overmint3Test is Test {
    Overmint3 public overmint;
    Overmint3Attack public attacker;

    function setUp() public {
        overmint = new Overmint3();
    }

    function test_Attack() public {
        attacker = new Overmint3Attack(address(overmint));
        require(overmint.balanceOf(address(attacker)) == 5, "attacker did not mint");
        require(overmint.totalSupply() == 5, "total supply not 5");
    }

    function test_is_contract() public {
        assertEq(overmint.isContract(address(this)), true);
        assertEq(overmint.isContract(address(0x1)), false);
    }
}
