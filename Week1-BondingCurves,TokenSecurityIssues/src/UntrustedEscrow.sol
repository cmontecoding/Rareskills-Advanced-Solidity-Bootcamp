// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

///@notice Untrusted escrow. Create a contract where a buyer can put an arbitrary
/// ERC20 token into a contract and a seller can withdraw it 3 days later.
/// Based on your readings above, what issues do you need to defend against?
/// Create the safest version of this that you can while guarding against issues that you cannot control.
/// Does your contract handle fee-on transfer tokens or non-standard ERC20 tokens.
contract UntrustedEscrow is Ownable {
    using SafeERC20 for IERC20;

    address public buyer;
    address public seller;
    IERC20 public token;
    uint256 public depositTime;
    uint256 public constant WITHDRAW_DELAY = 3 days;
    bool public deposited;

    constructor() Ownable(msg.sender) {}

    function initialize(
        address _buyer,
        address _seller,
        IERC20 _token
    ) external onlyOwner {
        require(buyer == address(0), "Contract is already initialized");
        buyer = _buyer;
        seller = _seller;
        token = _token;
    }

    function deposit(uint256 amount) external {
        require(msg.sender == buyer, "Only the buyer can deposit");
        require(!deposited, "You have already deposited");
        deposited = true;
        depositTime = block.timestamp;

        token.safeTransferFrom(buyer, address(this), amount);
    }

    function withdraw() external {
        require(msg.sender == seller, "Only the seller can withdraw");
        require(depositTime != 0, "Nothing is deposited yet");
        require(
            block.timestamp >= depositTime + WITHDRAW_DELAY,
            "Withdrawal time has not arrived yet"
        );
        uint256 balance = token.balanceOf(address(this));

        token.safeTransfer(seller, balance);
    }

    /// @notice The Owner can recover the ERC20 token that was deposited
    function recoverERC20(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            tokenAddress != address(token),
            "Cannot recover the deposited token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}
