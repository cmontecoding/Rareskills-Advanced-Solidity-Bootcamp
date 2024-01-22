// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {DeleteUser, DeleteUserAttack} from "../src/DeleteUser.sol";

contract DeleteUserTest is Test {
    DeleteUser public deleteUser;
    DeleteUserAttack public deleteUserAttack;
    address user = address(0x1);

    function setUp() public {
        deleteUser = new DeleteUser();
        deleteUserAttack = new DeleteUserAttack{value: 1 ether}(address(deleteUser));
        vm.deal(address(deleteUser), 1 ether);
        require(address(deleteUser).balance == 1 ether);
        require(address(deleteUserAttack).balance == 1 ether);
    }

    function test_Attack() public {
        deleteUserAttack.Attack();
        assertEq(address(deleteUserAttack).balance, 2 ether);
        assertEq(address(deleteUser).balance, 0);
    }
}
