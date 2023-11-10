// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable2Step, Ownable} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ERC721Royalty, ERC721, ERC2981} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {BitMaps} from "openzeppelin-contracts/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

/// @notice Royal Apes NFTs contract. ERC721 with a supply of 1000. 2.5% Royalty.
/// @dev Uses ERC721, ERC2981, OZ BitMaps, OZ MerkleProof
/// @dev Using ERC721Royalty instead of 721 and 2981 separately because this combines them neatly
contract RoyalApes is Ownable2Step, ERC721Royalty {

    constructor(
        address _owner
    ) Ownable(_owner) ERC721("RoyalApes", "RYAP") {}

    function mint() public {

    }

    /// @notice Addresses in a merkle tree can mint at a discount
    function mintWithDiscount() public {

    }

    function withdrawFundsRaised() public onlyOwner {
        
    }
}
