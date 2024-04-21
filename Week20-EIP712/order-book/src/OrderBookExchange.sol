// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {PermitToken, Permit} from "./PermitToken.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

struct Order {
    address owner;
    address sellToken;
    address buyToken;
    uint256 sellAmount;
    uint256 buyAmount;
    uint256 expires;
    uint256 nonce;
}

struct PermitWithSig {
    Permit permit;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct OrderWithSig {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct SignedOrderAndPermit {
    OrderWithSig orderWithSig;
    PermitWithSig permitWithSig;
}

/// @dev didnt have time to cook orderbook so taken from tommyrharper to understand
contract OrderBookExchange is EIP712, Nonces {
    // TODO: merge order and permit into one struct
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(addres owner,address sellToken,address buyToken,uint256 sellAmount,uint256 buyAmount,uint256 expires,uint256 nonce)"
        );

    PermitToken public tokenA;
    PermitToken public tokenB;

    constructor(
        PermitToken _tokenA,
        PermitToken _tokenB
    ) EIP712("OrderBookExchange", "1") {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function matchOrders(
        SignedOrderAndPermit memory orderA,
        SignedOrderAndPermit memory orderB
    ) external {
        checkOrderIsValid(orderA.orderWithSig);
        checkOrderIsValid(orderB.orderWithSig);
        checkOrdersMatch(orderA.orderWithSig.order, orderB.orderWithSig.order);
        checkOrderMatchesPermit(
            orderA.orderWithSig.order,
            orderA.permitWithSig.permit
        );
        checkOrderMatchesPermit(
            orderB.orderWithSig.order,
            orderB.permitWithSig.permit
        );

        executePermit(orderA);
        executePermit(orderB);

        doSwap(orderA.orderWithSig.order, orderB.orderWithSig.order);
    }

    function doSwap(Order memory orderA, Order memory orderB) internal {
        (uint256 amountForA, uint256 amountForB) = calculateSwapAmounts(
            orderA.sellAmount,
            orderA.buyAmount,
            orderB.sellAmount,
            orderB.buyAmount
        );
        /// @dev will revert if insufficient allowance
        tokenA.transferFrom(orderA.owner, orderB.owner, amountForB);
        tokenB.transferFrom(orderB.owner, orderA.owner, amountForA);
    }

    function calculateSwapAmounts(
        uint256 sellAmountA,
        uint256 buyAmountA,
        uint256 sellAmountB,
        uint256 buyAmountB
    ) internal pure returns (uint256 amountForA, uint256 amountForB) {
        // A is willing to sell more than B is willing to buy
        if (sellAmountA > buyAmountB) {
            // hence do the smaller (Bs) swap
            amountForB = buyAmountB;
            amountForA = sellAmountB;
        } else {
            // A is willing to sell less than B is willing to buy
            // hence do the larger (As) swap
            amountForA = buyAmountA;
            amountForB = sellAmountA;
        }
    }

    function executePermit(SignedOrderAndPermit memory order) internal {
        address token = order.orderWithSig.order.sellToken;
        PermitWithSig memory permitWithSig = order.permitWithSig;
        PermitToken(token).permit(
            permitWithSig.permit.owner,
            permitWithSig.permit.spender,
            permitWithSig.permit.value,
            permitWithSig.permit.deadline,
            permitWithSig.v,
            permitWithSig.r,
            permitWithSig.s
        );
    }

    function checkOrderMatchesPermit(
        Order memory order,
        Permit memory permit
    ) internal pure {
        require(order.owner == permit.owner, "wrong owner");
    }

    function checkOrdersMatch(
        Order memory orderA,
        Order memory orderB
    ) internal pure {
        require(orderA.sellToken == orderB.buyToken, "wrong tokens");
        require(orderA.buyToken == orderB.sellToken, "wrong tokens");
        require(orderA.buyAmount > 0, "zero buy amount");
        require(orderB.buyAmount > 0, "zero buy amount");
        require(orderA.sellAmount > 0, "zero sell amount");
        require(orderB.sellAmount > 0, "zero sell amount");
        checkRatiosMatch(
            orderA.sellAmount,
            orderA.buyAmount,
            orderB.sellAmount,
            orderB.buyAmount
        );
    }

    function checkRatiosMatch(
        uint256 sellAmountA,
        uint256 buyAmountA,
        uint256 sellAmountB,
        uint256 buyAmountB
    ) internal pure {
        if (sellAmountA == buyAmountA) {
            require(sellAmountB == buyAmountB, "wrong ratios");
        } else if (sellAmountA > buyAmountA) {
            uint256 ratioA = sellAmountA / buyAmountA;
            uint256 ratioB = buyAmountB / sellAmountB;
            require(ratioA == ratioB, "wrong ratios");
        } else {
            uint256 ratioA = buyAmountA / sellAmountA;
            uint256 ratioB = sellAmountB / buyAmountB;
            require(ratioA == ratioB, "wrong ratios");
        }
    }

    function checkOrderIsValid(OrderWithSig memory orderWithSig) internal {
        checkOrderIsValid(
            orderWithSig.order,
            orderWithSig.v,
            orderWithSig.r,
            orderWithSig.s
        );
    }

    function checkOrderIsValid(
        Order memory order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        if (block.timestamp > order.expires) {
            revert ExpiredSignature(order.expires);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.owner,
                order.sellToken,
                order.buyToken,
                order.sellAmount,
                order.buyAmount,
                order.expires,
                _useNonce(order.owner)
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != order.owner) {
            revert InvalidSigner(signer, order.owner);
        }
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    error ExpiredSignature(uint256 deadline);
    error InvalidSigner(address signer, address owner);
}