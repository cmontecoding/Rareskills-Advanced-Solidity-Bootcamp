// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {RoyalApes} from "./RoyalApes.sol";
import {StakingToken} from "./StakingToken.sol";

/// @notice Staking System contract for Royal Apes NFTs
/// @notice Users can stake a Royal Ape and receive
/// 10 StakingToken per 24 hours.
/// @notice Users can withdraw their NFT anytime
/// @dev The contract takes possesion of the NFT (escrow)
contract StakingSystem is IERC721Receiver {
    RoyalApes public immutable royalApes;
    StakingToken public immutable stakingToken;

    /// @dev mapping from tokenId to owner
    mapping(uint256 => address) public stakedApeOwner;

    /// @dev mapping from address to staked status
    mapping(address => bool) public isStaked;

    /// @dev mapping from address to last claimed time
    mapping(address => uint256) public lastClaimedTime;

    uint256 public constant MINT_AMOUNT_PER_DAY = 10 * 10e18;

    constructor(address _royalApesAddress, address _stakingTokenAddress) {
        royalApes = RoyalApes(_royalApesAddress);
        stakingToken = StakingToken(_stakingTokenAddress);
    }

    function stake(uint256 tokenId) public {
        require(isStaked[msg.sender] == false, "You already have a staked Ape");
        stakedApeOwner[tokenId] = msg.sender;
        isStaked[msg.sender] = true;
        /// @dev set last claimed time to now
        /// to prevent users from claiming immediately
        lastClaimedTime[msg.sender] = block.timestamp;
        royalApes.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(
            stakedApeOwner[tokenId] == msg.sender,
            "You do not own this staked Ape"
        );
        stakedApeOwner[tokenId] = address(0);
        isStaked[msg.sender] = false;
        lastClaimedTime[msg.sender] = 0;
        royalApes.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawTokens() public {
        require(isStaked[msg.sender] == true, "You do not have a staked Ape");
        uint256 timeElapsed = block.timestamp - lastClaimedTime[msg.sender];
        require(timeElapsed >= 1 days, "You cannot claim yet");
        lastClaimedTime[msg.sender] = block.timestamp;
        /// @dev mint proportional amount of tokens based on time elapsed
        stakingToken.mint(msg.sender, timeElapsed * MINT_AMOUNT_PER_DAY / 1 days);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
