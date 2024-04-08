// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CounterUpgradeable is UUPSUpgradeable {
    uint256 public number;

    constructor() {}

    function initialize() public initializer {
        number = 0;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function _authorizeUpgrade(address _newImplementation) internal override {}

}

contract CounterUpgradeableV2 is UUPSUpgradeable {
    uint256 public number;

    constructor() {}

    function initialize() public initializer {
        number = 0;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number = number + 2;
    }

    function _authorizeUpgrade(address _newImplementation) internal override {}
}

