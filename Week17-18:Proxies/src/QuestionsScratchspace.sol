// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CounterUpgradeable is UUPSUpgradeable {
    uint256 public number;
    uint256 public immutable x;

    constructor() {
        x = 2;
    }

    function initialize() public initializer {
        number = 0;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function selfDestruct() public {
        selfdestruct(payable(address(0)));
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function codesize() public view returns (uint256) {
        uint256 cs;
        assembly {
            cs := extcodesize(address())
        }
        return cs;
    }

    function revert() public pure {
        revert();
    }

    function readImmutable() public view returns (uint256) {
        return x;
    }

    function _authorizeUpgrade(address _newImplementation) internal override {}

}

contract DelegateCall {

    function delegate(address impl) external returns (uint256, address msgsender) {
        (bool ok, bytes memory result) = impl.delegatecall(abi.encodeWithSignature("number()"));
        return (abi.decode(result, (uint256)), msg.sender);
    }

    function emptyDelegate(address impl) external returns (uint256, address msgsender) {
        (bool ok, bytes memory result) = impl.delegatecall(abi.encodeWithSignature(""));
        return (abi.decode(result, (uint256)), msg.sender);
    }

    fallback() external {
       
    }

}