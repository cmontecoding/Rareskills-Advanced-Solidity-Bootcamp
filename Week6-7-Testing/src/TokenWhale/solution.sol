pragma solidity ^0.4.21;

import "./TokenWhaleChallenge.sol";

contract TestToken is TokenWhaleChallenge {
    address echidna = msg.sender;

    function TestToken() public {
        TokenWhaleChallenge(msg.sender);
    }

    // constuctor() {
    //     TokenWhaleChallenge(msg.sender);
    // }

    function echidna_test_balance() public view returns (bool) {
        return isComplete() == false;
    }
}