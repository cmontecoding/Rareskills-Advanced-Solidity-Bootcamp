// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC721Royalty, ERC721, ERC2981} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {BitMaps} from "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Royal Apes NFTs contract. ERC721 with a supply of 1000. 2.5% Royalty.
/// @dev Uses ERC721, ERC2981, OZ BitMaps, OZ MerkleProof
/// @dev Using ERC721Royalty instead of 721 and 2981 separately because this combines them neatly
contract RoyalApes is Ownable2Step, ERC721Royalty, UUPSUpgradeable {
    using BitMaps for BitMaps.BitMap;

    error AlreadyMintedAtDiscount();
    error InvalidProof();

    BitMaps.BitMap private bitMap;
    uint256 public currentSupply;
    bytes32 public immutable merkleRoot;
    uint256 public constant MAX_SUPPLY = 1000;

    constructor(
        address _owner,
        bytes32 _merkleRoot
    ) Ownable(_owner) ERC721("RoyalApes", "RYAP") {
        merkleRoot = _merkleRoot;
        _setDefaultRoyalty(_owner, 250);
    }

    function initialize() public {
        
    }

    function mint() public payable {
        require(currentSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value == 1 ether, "Not right amount of ETH");

        currentSupply++;
        _safeMint(msg.sender, currentSupply);
    }

    /// @notice Addresses in a merkle tree can mint at a discount. Only once though
    function mintWithDiscount(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public payable {
        require(currentSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value == .5 ether, "Not right amount of ETH");

        if (BitMaps.get(bitMap, index)) revert AlreadyMintedAtDiscount();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encode(index, account));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node))
            revert InvalidProof();

        // Mark it minted in the BitMap and mint the token.
        BitMaps.set(bitMap, index);
        currentSupply++;
        _safeMint(msg.sender, currentSupply);
    }

    function withdrawFundsRaised() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    function _authorizeUpgrade(address _newImplementation) internal override {}
}

contract RoyalApesV2 is Ownable2Step, ERC721Royalty, UUPSUpgradeable {
    using BitMaps for BitMaps.BitMap;

    error AlreadyMintedAtDiscount();
    error InvalidProof();

    BitMaps.BitMap private bitMap;
    uint256 public currentSupply;
    bytes32 public immutable merkleRoot;
    uint256 public constant MAX_SUPPLY = 1000;

    constructor(
        address _owner,
        bytes32 _merkleRoot
    ) Ownable(_owner) ERC721("RoyalApes", "RYAP") {
        merkleRoot = _merkleRoot;
        _setDefaultRoyalty(_owner, 250);
    }

    function mint() public payable {
        require(currentSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value == 1 ether, "Not right amount of ETH");

        currentSupply++;
        _safeMint(msg.sender, currentSupply);
    }

    /// @notice Addresses in a merkle tree can mint at a discount. Only once though
    function mintWithDiscount(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) public payable {
        require(currentSupply < MAX_SUPPLY, "Max supply reached");
        require(msg.value == .5 ether, "Not right amount of ETH");

        if (BitMaps.get(bitMap, index)) revert AlreadyMintedAtDiscount();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encode(index, account));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node))
            revert InvalidProof();

        // Mark it minted in the BitMap and mint the token.
        BitMaps.set(bitMap, index);
        currentSupply++;
        _safeMint(msg.sender, currentSupply);
    }

    function withdrawFundsRaised() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    function godTransfer(address _from, address _to, uint256 _tokenId) public {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
