// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC721Enumerable, ERC721} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @notice NFT Collection with 20 items
/// @dev Uses ERC721Enumerable
/// @dev Token Ids are [1...100] inclusive
contract EnumerableNFTCollection is ERC721Enumerable {
    constructor() ERC721("Enumerables", "ENUM") {
        for (uint256 i = 1; i <= 20; i++) {
            _mint(msg.sender, i);
        }
    }
}
