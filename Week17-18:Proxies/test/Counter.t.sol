// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public implementation;

    function setUp() public {
        implementation = new Counter();
        implementation.setNumber(0);
    }

    function test_Increment() public {
        implementation.increment();
        assertEq(implementation.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        implementation.setNumber(x);
        assertEq(implementation.number(), x);
    }
}

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CounterUpgradeable, CounterUpgradeableV2} from "../src/CounterUpgradeable.sol";

contract CounterTestUpgradeable is Test {
    CounterUpgradeable public implementation;
    ERC1967Proxy public proxy;
    CounterUpgradeable public counter;

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
        counter = CounterUpgradeable(address(proxy));
    }

    function test_Increment() public {
        assertEq(counter.number(), 0);
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testUpgrade() public {
        counter.increment();

        // deploy new implementation
        CounterUpgradeableV2 newImplementation = new CounterUpgradeableV2();
        // upgrade proxy to new implementation
        counter.upgradeToAndCall(address(newImplementation), "");        

        assertEq(counter.number(), 1);
        counter.increment();
        assertEq(counter.number(), 3);
    }
}