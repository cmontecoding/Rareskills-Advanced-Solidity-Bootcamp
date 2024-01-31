// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {OligarchyNFT, CommunityWallet, Governance, GovernanceAttacker} from "../src/Viceroy.sol";

contract ViceroyTest is Test {
    OligarchyNFT public nft;
    Governance public governance;
    CommunityWallet public communityWallet;
    GovernanceAttacker public attacker;
    address user = address(0x1);
    address attackerWallet = address(0x2);

    function setUp() public {
        vm.prank(attackerWallet);
        attacker = new GovernanceAttacker();
        nft = new OligarchyNFT(address(attacker));
        governance = new Governance{value: 10 ether}(nft);
        communityWallet = governance.communityWallet();
        
        assertEq(address(communityWallet).balance, 10 ether);
    }

    function test_Attack() public {
        vm.prank(attackerWallet);
        attacker.attack(governance);
        assertEq(address(communityWallet).balance, 0);
    }
}