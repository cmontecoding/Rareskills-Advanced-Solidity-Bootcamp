// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.4.21;

import "./TokenWhaleChallenge.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.4.25 --always-install
///      echidna src/TokenWhale/solution.sol --contract TokenWhaleChallengeTest
///      ```
contract TokenWhaleChallengeTest is TokenWhaleChallenge {
    address echidna = msg.sender;

    function TokenWhaleChallengeTest() public TokenWhaleChallenge(msg.sender) {}

    function echidna_test_balance() public view returns (bool) {
        return !isComplete();
    }
}