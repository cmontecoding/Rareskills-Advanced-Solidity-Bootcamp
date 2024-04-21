// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PermitToken} from "../src/PermitToken.sol";
import {OrderBookExchange, Order} from "../src/OrderBookExchange.sol";

/// @dev didnt have time to cook orderbook so taken from tommyrharper to understand
contract OrderBookSigUtils is Test {
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(addres owner,address sellToken,address buyToken,uint256 sellAmount,uint256 buyAmount,uint256 expires,uint256 nonce)"
        );

    OrderBookExchange public orderBookExchange;

    constructor(OrderBookExchange _orderBookExchange) {
        orderBookExchange = _orderBookExchange;
    }

    // computes the hash of a ballot
    function getStructHash(
        Order memory _order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    _order.owner,
                    _order.sellToken,
                    _order.buyToken,
                    _order.sellAmount,
                    _order.buyAmount,
                    _order.expires,
                    _order.nonce
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(
        Order memory _order
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    orderBookExchange.DOMAIN_SEPARATOR(),
                    getStructHash(_order)
                )
            );
    }

    // computes incorrect hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getDodgyTypedDataHash(
        Order memory _order
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x02",
                    orderBookExchange.DOMAIN_SEPARATOR(),
                    getStructHash(_order)
                )
            );
    }

    function getSignedOrder(
        address sellToken,
        address buyToken,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 _privateKey
    ) public view returns (Order memory order, uint8 v, bytes32 r, bytes32 s) {
        address owner = vm.addr(_privateKey);

        uint256 nextNonce = orderBookExchange.nonces(owner);

        order = Order({
            owner: owner,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: sellAmount,
            buyAmount: buyAmount,
            expires: block.timestamp + 1000,
            nonce: nextNonce
        });

        bytes32 digest = getTypedDataHash(order);
        (v, r, s) = vm.sign(_privateKey, digest);

        return (order, v, r, s);
    }
}