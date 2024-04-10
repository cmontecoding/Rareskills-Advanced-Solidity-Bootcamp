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
    DelegateCall public delegateCall;

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
        delegateCall = new DelegateCall();
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
        (uint256 result, ) = delegateCall.delegate(address(counter));
        assertEq(result, 0);
    }

    // If a proxy calls an implementation, and the implementation
    // self-destructs in the function that gets called, what happens? 
    function testSelfDestruct() public {
        counterUpgradeable.selfDestruct();
        counterUpgradeable.increment();
        assertEq(counterUpgradeable.number(), 0);
    }

    // If a proxy makes a delegatecall to A, and
    // A does address(this).balance, whose balance
    // is returned, the proxy's or A? 
    function testBalance() public {
        vm.deal(address(implementation), 5);
        vm.deal(address(counterUpgradeable), 10);

        uint256 bal = counterUpgradeable.balance();
        assertEq(bal, 10);
    }

    // If a proxy makes a delegatecall to A, and
    // A calls codesize, is codesize the size of the proxy or A? 
    function testCodesize() public {
        uint256 proxycs = counterUpgradeable.codesize();
        uint256 impcs = implementation.codesize();
        assertTrue(proxycs != impcs);
    }

    // If a delegatecall is made to a function that reverts,
    // what does the delegatecall do? 
    function testRevert() public {
        counterUpgradeable.revert();
    }

    // If a delegatecall is made to a function that reads an
    // immutable variable, where is the variable read from?
    function testReadImmutable() public {
        uint256 x = counterUpgradeable.readImmutable();
        assertEq(x, 2);
    }

    // If a delegatecall is made to a contract that makes a
    // delegatecall to another contract, who is msg.sender
    // in the proxy, the first contract, and the second contract? 
    function testDelegateCall() public {
        (uint256 result, address msgsender) = delegateCall.emptyDelegate(address(delegateCall));
        //assertEq(msgsender, address(this));
    }
}