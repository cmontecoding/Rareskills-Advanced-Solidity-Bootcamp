// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract GuessTheSecretNumber {
    bytes32 answerHash =
        0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function guess(uint8 n) public payable returns (bool) {
        require(msg.value == 1 ether);

        if (keccak256(abi.encodePacked(n)) == answerHash) {
            (bool ok, ) = msg.sender.call{value: 2 ether}("");
            require(ok, "Failed to Send 2 ether");
        }
        return true;
    }
}

// Write your exploit codes below
contract ExploitContract {
    bytes32 answerHash =
        0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    function Exploiter() public view returns (uint8) {
        /// @dev there is a uint8 value that when packed and hashed, returns the answerHash
        /// so we loop through all the possible uint8 values and return the one that matches the answerHash
        /// (uint8).max is only 2^8 - 1 = 255 which is why we can brute force it
        for (uint8 i = 0; i < type(uint8).max; i++) {
            if (keccak256(abi.encodePacked(i)) == answerHash) {
                return i;
            }
        }
        return type(uint8).max;
    }
}
