// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Dex.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise1/template.sol
///      ```
contract Test is Dex {

    address public emptyAddress = address(0x1);

    constructor() Dex(address(emptyAddress)) {
        token1 = address(new SwappableToken(address(this), "Token1", "TK1", 110));
        token2 = address(new SwappableToken(address(this), "Token2", "TK2", 110));
        SwappableToken(token1).transfer(msg.sender, 10);
        SwappableToken(token2).transfer(msg.sender, 10);

        /// @dev make sure token balances are setup correctly
        assert(balanceOf(token1, address(this)) == 100);
        assert(balanceOf(token2, address(this)) == 100);
        assert(balanceOf(token1, msg.sender) == 10);
        assert(balanceOf(token2, msg.sender) == 10);
    }

    function echidna_test_drain_contract() public view returns (bool) {
        return
            balanceOf(token1, address(this)) > 99 &&
            balanceOf(token2, address(this)) > 10;
    }

    function echidna_test_random_address() public view returns (bool) {
        return owner() == emptyAddress;
    }

    function echidna_test_token_initialization() public view returns (bool) {
        return token1 != address(0) && token2 != address(0);
    }
}