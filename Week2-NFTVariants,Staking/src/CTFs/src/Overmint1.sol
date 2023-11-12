// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract Overmint1 is ERC721 {
    using Address for address;
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint1", "AT") {}

    function mint() external {
        require(amountMinted[msg.sender] <= 3, "max 3 NFTs");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    function success(address _attacker) external view returns (bool) {
        return balanceOf(_attacker) == 5;
    }
}