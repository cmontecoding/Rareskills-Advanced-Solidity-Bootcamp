// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

///@notice Token sale and buyback with bonding curve.
/// The more tokens a user buys, the more expensive the token becomes.
/// To keep things simple, use a linear bonding curve.
contract BondingCurve is ERC20, Ownable2Step {
    uint256 public immutable initialPrice;
    uint256 public immutable slope;
    uint256 public maxGasLimit = 160_000;

    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 paid,
        uint256 newSupply
    );
    event TokensSold(
        address indexed seller,
        uint256 amount,
        uint256 received,
        uint256 newSupply
    );

    constructor(uint256 _initialPrice, uint256 _slope) Ownable(msg.sender) ERC20("Bond", "BOND") {
        initialPrice = _initialPrice;
        slope = _slope;
    }

    /// @dev Modifier to check the gas limit
    /// (to prevent sandwhich attacks)
    modifier withinGasLimit() {
        require(gasleft() <= maxGasLimit, "Gas limit exceeded");
        _;
    }

    function purchaseTokens(
        uint256 _tokensToBuy
    ) external payable withinGasLimit {
        require(_tokensToBuy > 0, "Invalid token amount");
        uint256 price = calculatePurchasePrice(_tokensToBuy);
        require(msg.value >= price, "Insufficient payment");

        _mint(msg.sender, _tokensToBuy);

        emit TokensPurchased(msg.sender, _tokensToBuy, price, totalSupply());
    }

    function sellTokens(uint256 _tokensToSell) external {
        require(_tokensToSell > 0, "Invalid token amount");

        uint256 price = calculateSalePrice(_tokensToSell);

        _burn(msg.sender, _tokensToSell);

        (bool success, ) = payable(msg.sender).call{value: price}("");
        require(success, "Transfer failed");
        emit TokensSold(msg.sender, _tokensToSell, price, totalSupply());
    }

    function calculatePurchasePrice(
        uint256 _tokensToBuy
    ) public view returns (uint256) {
        uint256 newSupply = totalSupply() + _tokensToBuy;
        return calculatePriceForSupply(totalSupply(), newSupply);
    }

    function calculateSalePrice(
        uint256 _tokensToSell
    ) public view returns (uint256) {
        uint256 newSupply = totalSupply() - _tokensToSell;
        return calculatePriceForSupply(newSupply, totalSupply());
    }

    /// @notice calculate the price of tokens given the supply
    function calculatePriceForSupply(
        uint256 newSupply,
        uint256 prevSupply
    ) internal view returns (uint256) {
        if (newSupply == prevSupply) {
            return 0;
        }

        /// @dev arithmetic series formula to calculate the sum of a series of numbers.
        /// This formula is used to find the sum of prices for a continuous range of tokens,
        /// considering that the price is increasing linearly
        uint256 totalPrice = ((initialPrice +
            initialPrice +
            (slope * (newSupply + prevSupply - 1))) *
            (prevSupply - newSupply)) / 2;
        return totalPrice;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setMaxGasLimit(uint256 _newLimit) external onlyOwner {
        maxGasLimit = _newLimit;
    }
}
