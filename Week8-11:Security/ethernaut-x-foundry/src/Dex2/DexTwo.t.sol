// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";
// import {DexTwo, SwappableTokenTwo} from "./DexTwo.sol";
// import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// contract AttackDexTwoToken is SwappableTokenTwo {
    
// }

// contract DexTwoTest is Test {
//     DexTwo public dex;
//     SwappableTokenTwo public token1;
//     SwappableTokenTwo public token2;

//     address owner;

//     function setUp() public {
//         owner = address(0x1);

//         vm.startPrank(owner);
//         dex = new DexTwo();
//         token1 = new SwappableTokenTwo(
//             address(dex),
//             "SwappableToken1",
//             "ST1",
//             110
//         );
//         token2 = new SwappableTokenTwo(
//             address(dex),
//             "SwappableToken2",
//             "ST2",
//             110
//         );

//         assert(token1.balanceOf(owner) == 110);
//         assert(token2.balanceOf(owner) == 110);

//         dex.setTokens(address(token1), address(token2));

//         token1.transfer(address(dex), 100);
//         token2.transfer(address(dex), 100);
//         token1.transfer(address(this), 10);
//         token2.transfer(address(this), 10);

//         assert(token1.balanceOf(owner) == 0);
//         assert(token2.balanceOf(owner) == 0);
//         assert(token1.balanceOf(address(dex)) == 100);
//         assert(token2.balanceOf(address(dex)) == 100);
//         assert(token1.balanceOf(address(this)) == 10);
//         assert(token2.balanceOf(address(this)) == 10);

//         vm.stopPrank();
//     }

//     function test_Attack_Dex() public {
//     }
// }