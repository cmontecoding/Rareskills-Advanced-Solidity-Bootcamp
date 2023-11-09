// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract BondingCurveTest is Test {
    BondingCurve bond;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        bond = new BondingCurve(1, 2);

        vm.deal(admin, 1000);
        vm.deal(user1, 1000);
    }

    receive() external payable {}

    function testBuyAndSellOne() public {
        assertEq(address(this).balance, 1000);

        bond.purchaseTokens{value: 1, gas: 150000}(1);
        assertEq(bond.balanceOf(address(this)), 1);
        assertEq(address(this).balance, 999);

        /// @dev sell and get money back
        bond.sellTokens(1);
        assertEq(address(this).balance, 1000);
    }

    /// @notice make sure price increases with each token
    function testBuyThree() public {
        bond.purchaseTokens{value: 9, gas: 150000}(3);
        assertEq(bond.balanceOf(address(this)), 3);
    }

    /// @notice make sure price increases with each token
    function testBuyMultiple() public {
        bond.purchaseTokens{value: 1, gas: 150000}(1);
        bond.purchaseTokens{value: 3, gas: 150000}(1);
        bond.purchaseTokens{value: 5, gas: 150000}(1);
        assertEq(bond.balanceOf(address(this)), 3);
    }

    function testSell() public {
        assertEq(address(this).balance, 1000);

        bond.purchaseTokens{value: 1, gas: 150000}(1);
        vm.prank(user1);
        bond.purchaseTokens{value: 3, gas: 150000}(1);

        /// @dev first person who bought sells and makes a profit
        bond.sellTokens(1);
        assertEq(bond.balanceOf(address(this)), 0);
        assertEq(address(this).balance, 1002);
    }

    function testOutsideGasLimit() public {
        vm.expectRevert("Gas limit exceeded");
        bond.purchaseTokens{value: 1, gas: 165000}(1);
    }
}
