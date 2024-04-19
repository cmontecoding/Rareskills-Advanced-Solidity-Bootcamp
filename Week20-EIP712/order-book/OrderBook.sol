//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;



contract OrderBook is EIP712{
    struct Order {
        address maker;
        address token;
        uint256 amount;
        uint256 price;
    }

    mapping(bytes32 => Order) public orders;

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    function placeOrder(Order memory order) public {
        bytes32 hash = hashOrder(order);
        orders[hash] = order;
    }
}