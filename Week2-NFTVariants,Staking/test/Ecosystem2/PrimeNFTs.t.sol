// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {EnumerableNFTCollection, PrimeNFTs} from "../../src/Ecosystem2/PrimeNFTs.sol";

contract PrimeNFTsTest is Test {
    EnumerableNFTCollection enumerableNFTCollection;
    PrimeNFTs primeNFTs;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        enumerableNFTCollection = new EnumerableNFTCollection();
        primeNFTs = new PrimeNFTs(address(enumerableNFTCollection));

        enumerableNFTCollection.transferFrom(admin, user1, 19);
        assertEq(enumerableNFTCollection.balanceOf(user1), 1);
        assertEq(enumerableNFTCollection.ownerOf(19), user1);
        assertEq(enumerableNFTCollection.balanceOf(admin), 19);
    }

    function testCountPrimeNFTs() public {
        assertEq(primeNFTs.countPrimeNFTs(admin), 7);
        assertEq(primeNFTs.countPrimeNFTs(user1), 1);
        assertEq(primeNFTs.countPrimeNFTs(user2), 0);
    }

    function testIsPrime() public {
        assertEq(primeNFTs.isPrime(1), false);
        assertEq(primeNFTs.isPrime(2), true);
        assertEq(primeNFTs.isPrime(3), true);
        assertEq(primeNFTs.isPrime(4), false);
        assertEq(primeNFTs.isPrime(5), true);
        assertEq(primeNFTs.isPrime(6), false);
        assertEq(primeNFTs.isPrime(7), true);
        assertEq(primeNFTs.isPrime(8), false);
        assertEq(primeNFTs.isPrime(9), false);
        assertEq(primeNFTs.isPrime(10), false);
        assertEq(primeNFTs.isPrime(11), true);
        assertEq(primeNFTs.isPrime(12), false);
        assertEq(primeNFTs.isPrime(13), true);
        assertEq(primeNFTs.isPrime(14), false);
        assertEq(primeNFTs.isPrime(15), false);
        assertEq(primeNFTs.isPrime(16), false);
        assertEq(primeNFTs.isPrime(17), true);
        assertEq(primeNFTs.isPrime(18), false);
        assertEq(primeNFTs.isPrime(19), true);
        assertEq(primeNFTs.isPrime(20), false);
        assertEq(primeNFTs.isPrime(21), false);
        assertEq(primeNFTs.isPrime(22), false);
        assertEq(primeNFTs.isPrime(23), true);
        assertEq(primeNFTs.isPrime(24), false);
        assertEq(primeNFTs.isPrime(25), false);
        assertEq(primeNFTs.isPrime(26), false);
        assertEq(primeNFTs.isPrime(27), false);
        assertEq(primeNFTs.isPrime(28), false);
        assertEq(primeNFTs.isPrime(29), true);
        assertEq(primeNFTs.isPrime(30), false);
    }
}
