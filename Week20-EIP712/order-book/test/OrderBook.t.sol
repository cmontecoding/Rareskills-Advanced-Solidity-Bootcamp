// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OrderBookExchange, Order, SignedOrderAndPermit, OrderWithSig, PermitWithSig} from "../src/OrderBookExchange.sol";
import {PermitToken, Permit} from "../src/PermitToken.sol";
import {SigUtils} from "./SigUtils.sol";
import {OrderBookExchangeTestHelpers} from "./OrderBookExchangeTestHelpers.sol";

/// @dev didnt have time to cook orderbook so taken from tommyrharper to understand
contract OrderBookExchangeTest is OrderBookExchangeTestHelpers {
    function test_match_order() public {
        PermitWithSig memory permitWithSigA = getTokenAPermitWithSig(100 ether);
        PermitWithSig memory permitWithSigB = getTokenBPermitWithSig(5 ether);
        OrderWithSig memory orderWithSigA = getTokenAOrderWithSig(
            100 ether,
            50 ether
        );
        OrderWithSig memory orderWithSigB = getTokenBOrderWithSig(
            5 ether,
            10 ether
        );

        SignedOrderAndPermit memory orderA = SignedOrderAndPermit(
            orderWithSigA,
            permitWithSigA
        );

        SignedOrderAndPermit memory orderB = SignedOrderAndPermit(
            orderWithSigB,
            permitWithSigB
        );

        orderBookExchange.matchOrders(orderA, orderB);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenA.balanceOf(user2), 10 ether);
        assertEq(tokenB.balanceOf(user1), 5 ether);
    }

    function test_match_order_equal_volume() public {
        PermitWithSig memory permitWithSigA = getTokenAPermitWithSig(100 ether);
        PermitWithSig memory permitWithSigB = getTokenBPermitWithSig(50 ether);
        OrderWithSig memory orderWithSigA = getTokenAOrderWithSig(
            100 ether,
            50 ether
        );
        OrderWithSig memory orderWithSigB = getTokenBOrderWithSig(
            50 ether,
            100 ether
        );

        SignedOrderAndPermit memory orderA = SignedOrderAndPermit(
            orderWithSigA,
            permitWithSigA
        );

        SignedOrderAndPermit memory orderB = SignedOrderAndPermit(
            orderWithSigB,
            permitWithSigB
        );

        orderBookExchange.matchOrders(orderA, orderB);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenA.balanceOf(user2), 100 ether);
        assertEq(tokenB.balanceOf(user1), 50 ether);
    }

    function test_match_order_a_less() public {
        PermitWithSig memory permitWithSigA = getTokenAPermitWithSig(10 ether);
        PermitWithSig memory permitWithSigB = getTokenBPermitWithSig(50 ether);
        OrderWithSig memory orderWithSigA = getTokenAOrderWithSig(
            10 ether,
            5 ether
        );
        OrderWithSig memory orderWithSigB = getTokenBOrderWithSig(
            50 ether,
            100 ether
        );

        SignedOrderAndPermit memory orderA = SignedOrderAndPermit(
            orderWithSigA,
            permitWithSigA
        );

        SignedOrderAndPermit memory orderB = SignedOrderAndPermit(
            orderWithSigB,
            permitWithSigB
        );

        orderBookExchange.matchOrders(orderA, orderB);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenA.balanceOf(user2), 10 ether);
        assertEq(tokenB.balanceOf(user1), 5 ether);
    }

    function test_match_order_switch_ratios() public {
        PermitWithSig memory permitWithSigA = getTokenAPermitWithSig(10 ether);
        PermitWithSig memory permitWithSigB = getTokenBPermitWithSig(150 ether);
        OrderWithSig memory orderWithSigA = getTokenAOrderWithSig(
            10 ether,
            15 ether
        );
        OrderWithSig memory orderWithSigB = getTokenBOrderWithSig(
            150 ether,
            100 ether
        );

        SignedOrderAndPermit memory orderA = SignedOrderAndPermit(
            orderWithSigA,
            permitWithSigA
        );

        SignedOrderAndPermit memory orderB = SignedOrderAndPermit(
            orderWithSigB,
            permitWithSigB
        );

        orderBookExchange.matchOrders(orderA, orderB);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenA.balanceOf(user2), 10 ether);
        assertEq(tokenB.balanceOf(user1), 15 ether);
    }

    function test_match_order_flat_ratio() public {
        PermitWithSig memory permitWithSigA = getTokenAPermitWithSig(10 ether);
        PermitWithSig memory permitWithSigB = getTokenBPermitWithSig(150 ether);
        OrderWithSig memory orderWithSigA = getTokenAOrderWithSig(
            10 ether,
            10 ether
        );
        OrderWithSig memory orderWithSigB = getTokenBOrderWithSig(
            150 ether,
            150 ether
        );

        SignedOrderAndPermit memory orderA = SignedOrderAndPermit(
            orderWithSigA,
            permitWithSigA
        );

        SignedOrderAndPermit memory orderB = SignedOrderAndPermit(
            orderWithSigB,
            permitWithSigB
        );

        orderBookExchange.matchOrders(orderA, orderB);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0 ether);
        assertEq(tokenA.balanceOf(user2), 10 ether);
        assertEq(tokenB.balanceOf(user1), 10 ether);
    }

    function test_permit_tokenA() public {
        (Permit memory permit, uint8 v, bytes32 r, bytes32 s) = getTokenAPermit(
            1 ether
        );

        executePermit(permit, v, r, s);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 0);

        vm.prank(address(orderBookExchange));
        tokenA.transferFrom(user1, address(orderBookExchange), 1 ether);

        assertEq(tokenA.balanceOf(address(orderBookExchange)), 1 ether);
    }

    function test_permit_tokenB() public {
        (Permit memory permit, uint8 v, bytes32 r, bytes32 s) = getTokenBPermit(
            1 ether
        );

        executePermit(permit, v, r, s);

        assertEq(tokenB.balanceOf(address(orderBookExchange)), 0);

        vm.prank(address(orderBookExchange));
        tokenB.transferFrom(user2, address(orderBookExchange), 1 ether);

        assertEq(tokenB.balanceOf(address(orderBookExchange)), 1 ether);
    }

    function test_order_user1() public {
        (Order memory order, uint8 v, bytes32 r, bytes32 s) = getTokenAOrder(
            1 ether,
            1 ether
        );

        checkOrderIsValid(order, v, r, s);
    }

    function test_order_user2() public {
        (Order memory order, uint8 v, bytes32 r, bytes32 s) = getTokenBOrder(
            1 ether,
            1 ether
        );

        checkOrderIsValid(order, v, r, s);
    }
}