// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./BondingCurve.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.0
///      echidna program-analysis/echidna/exercises/exercise1/template.sol
///      ```
contract Test is BondingCurve {

    constructor() BondingCurve(100, 1) {
    }

    /// @dev the price of a token should stay the same when buying and selling
    function echidna_test_buy_price() public returns (bool) {
        uint256 purchasePriceBefore = calculatePurchasePrice(1);
        /// @dev this mimics buying 1 token
        _update(address(0), address(this), 1);
        return purchasePriceBefore == calculateSalePrice(1);
    }

    function echidna_test_initial_price() public view returns (bool) {
        return initialPrice == 100;
    }

    function echidna_test_slope() public view returns (bool) {
        return slope == 1;
    }
}