// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EnumerableNFTCollection} from "./EnumerableNFTCollection.sol";

contract PrimeNFTs {
    EnumerableNFTCollection nftCollection;

    constructor(address _nftCollectionAddress) {
        nftCollection = EnumerableNFTCollection(_nftCollectionAddress);
    }

    function countPrimeNFTs(address owner) external view returns (uint256) {
        uint256 balance = nftCollection.balanceOf(owner);
        uint256 primeCount = 0;
        for (uint256 tokenIds = 0; tokenIds < balance; ) {
            uint256 tokenId = nftCollection.tokenOfOwnerByIndex(
                owner,
                tokenIds
            );
            if (isPrime(tokenId)) {
                primeCount++;
            }
            unchecked {
                tokenIds++;
            }
        }

        return primeCount;
    }

    function isPrime(uint256 number) public pure returns (bool) {
        /// @dev 1 or less is not prime
        if (number <= 1) {
            return false;
        }
        /// @dev 2 and 3 are prime
        if (number <= 3) {
            return true;
        }
        /// @dev multiples of 2 and 3 are not prime
        if (number % 2 == 0 || number % 3 == 0) {
            return false;
        }
        /// @dev all primes are of the form 6k ± 1, with the exception of 2 and 3
        /// @dev this checks if the number is divisible by i or i + 2 for each increment of 6
        for (uint256 i = 5; i * i <= number; ) {
            if (number % i == 0 || number % (i + 2) == 0) {
                return false;
            }
            unchecked {
                i += 6;
            }
        }
        return true;
    }
}
