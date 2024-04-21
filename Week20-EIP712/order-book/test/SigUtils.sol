// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {PermitToken, Permit} from "../src/PermitToken.sol";

/// @dev didnt have time to cook orderbook so taken from tommyrharper to understand
contract SigUtils is Test {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // computes the hash of a ballot
    function getStructHash(
        Permit memory _permit
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _permit.owner,
                    _permit.spender,
                    _permit.value,
                    _permit.nonce,
                    _permit.deadline
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(
        Permit memory _permit,
        PermitToken _permitToken
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _permitToken.DOMAIN_SEPARATOR(),
                    getStructHash(_permit)
                )
            );
    }

    // computes incorrect hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getDodgyTypedDataHash(
        Permit memory _permit,
        PermitToken _permitToken
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x02",
                    _permitToken.DOMAIN_SEPARATOR(),
                    getStructHash(_permit)
                )
            );
    }

    function getSignedPermit(
        PermitToken _permitToken,
        uint256 _privateKey,
        address _spender,
        uint256 _value
    )
        public
        view
        returns (Permit memory permit, uint8 v, bytes32 r, bytes32 s)
    {
        address owner = vm.addr(_privateKey);

        uint256 nextNonce = _permitToken.nonces(owner);

        permit = Permit({
            owner: owner,
            spender: _spender,
            value: _value,
            nonce: nextNonce,
            deadline: block.timestamp + 1000
        });

        bytes32 digest = getTypedDataHash(permit, _permitToken);
        (v, r, s) = vm.sign(_privateKey, digest);

        return (permit, v, r, s);
    }
}