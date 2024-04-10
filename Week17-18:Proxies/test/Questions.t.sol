// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CounterUpgradeable, DelegateCall} from "../src/QuestionsScratchspace.sol";
import {Counter} from "../src/Counter.sol";

contract QuestionsTest is Test {
    CounterUpgradeable public implementation;
    ERC1967Proxy public proxy;
    CounterUpgradeable public counterUpgradeable;
    Counter public counter;

    function setUp() public {
        // address proxy = Upgrades.deployUUPSProxy(
        //     "CounterUpgradeable.sol",
        //     abi.encodeCall(CounterUpgradeable.initialize, ())
        // );

        // deploy logic contract
        implementation = new CounterUpgradeable();
        // deploy proxy contract and point it to implementation
        proxy = new ERC1967Proxy(address(implementation), "");

        // initialize implementation contract
        address(proxy).call(abi.encodeWithSignature("initialize()"));

        // wrap proxy in CounterUpgradeable
        counterUpgradeable = CounterUpgradeable(address(proxy));

        counter = new Counter();
    }

    function test_Increment() public {
        assertEq(counterUpgradeable.number(), 0);
        counterUpgradeable.increment();
        assertEq(counterUpgradeable.number(), 1);
    }

    // When a contract calls another call via call,
    // delegatecall, or staticcall, how is information
    // passed between them? Where is this data stored? 
    function testInformation() public {
        DelegateCall delegateCall = new DelegateCall();
        uint256 result = delegateCall.delegate(address(counter));
        assertEq(result, 0);
    }
}