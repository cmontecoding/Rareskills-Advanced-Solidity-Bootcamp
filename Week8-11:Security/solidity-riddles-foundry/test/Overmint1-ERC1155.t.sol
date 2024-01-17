// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Overmint1_ERC1155, Attack} from "../src/Overmint1-ERC1155.sol";

contract Overmint1Test is Test {
    Overmint1_ERC1155 public overmint;
    Attack public attack;

    function setUp() public {
        overmint = new Overmint1_ERC1155();
        attack = new Attack(overmint);
    }

    function test_Attack() public {
        attack.attack();
        overmint.mint(1, "");
        overmint.mint(1, "");
        overmint.safeTransferFrom(address(this), address(attack), 1, 2, "");
        require(overmint.success(address(attack), 1), "not successful");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
