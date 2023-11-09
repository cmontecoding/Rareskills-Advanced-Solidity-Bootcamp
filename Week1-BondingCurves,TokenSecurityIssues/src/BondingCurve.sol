// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

///@notice Token sale and buyback with bonding curve.
/// The more tokens a user buys, the more expensive the token becomes.
/// To keep things simple, use a linear bonding curve.
contract BondingCurve is ERC20 {
    address public owner;
    uint256 public initialPrice;
    uint256 public slope;
    uint256 public supply;
    uint256 public buybackPool;
    uint256 public totalFundsRaised;
    uint256 public maxGasLimit = 160_000;

    mapping(address => uint256) public balances;

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

    constructor(uint256 _initialPrice, uint256 _slope) ERC20("Bond", "BOND") {
        owner = msg.sender;
        initialPrice = _initialPrice;
        slope = _slope;
        supply = 0;
        buybackPool = 0;
        totalFundsRaised = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
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

        supply = supply + _tokensToBuy;
        balances[msg.sender] = balances[msg.sender] + _tokensToBuy;
        totalFundsRaised = totalFundsRaised + price;

        _mint(msg.sender, _tokensToBuy);

        emit TokensPurchased(msg.sender, _tokensToBuy, price, supply);
    }

    function sellTokens(uint256 _tokensToSell) external {
        require(_tokensToSell > 0, "Invalid token amount");
        require(balances[msg.sender] >= _tokensToSell, "Insufficient balance");

        uint256 price = calculateSalePrice(_tokensToSell);
        supply = supply - _tokensToSell;
        balances[msg.sender] = balances[msg.sender] - _tokensToSell;
        totalFundsRaised = totalFundsRaised - price;

        _burn(msg.sender, _tokensToSell);

        payable(msg.sender).transfer(price);
        emit TokensSold(msg.sender, _tokensToSell, price, supply);
    }

    function calculatePurchasePrice(
        uint256 _tokensToBuy
    ) public view returns (uint256) {
        uint256 newSupply = supply + _tokensToBuy;
        return calculatePriceForSupply(supply, newSupply);
    }

    function calculateSalePrice(
        uint256 _tokensToSell
    ) public view returns (uint256) {
        uint256 newSupply = supply - _tokensToSell;
        return calculatePriceForSupply(newSupply, supply);
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
        payable(owner).transfer(address(this).balance);
    }

    function setMaxGasLimit(uint256 _newLimit) external onlyOwner {
        maxGasLimit = _newLimit;
    }
}
