// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Counter} from "../src/Counter.sol";

contract EchidnaTest is Counter {
    Counter counter;

    constructor() {
        number = 5;
    }

    function echidna_counter_always_greater_than_or_equal_0()
        public
        view
        returns (bool)
    {
        return number >= 5;
    }
}
