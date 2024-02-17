object "ERC1155" {
    code {
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }
    object "Runtime" {
        code {
            //Dispatcher
            switch getSelector()
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                //_mint(decodeAddress(0), decodeUint(1), decodeUint(2), decodeUint(3))
            }
            case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes) */{

            }
            case 0xf5298aca /* burn(address,uint256,uint256) */ {
            
            }
            case 0xf6eb127a /* burnBatch(address,uint256[],uint256[]) */ {

            }
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                //returnUint(balanceOf(decodeAddress(0), decodeUint(1)))
            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {

            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {

            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {

            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {

            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {

            }
            default {
                revert(0, 0)
            }

            function _mint(account, id, amount, dataOffset) {
                // revert if minting to zero address
                if eq(account, 0) {
                    revert(0, 0)
                }
                addBalance(account, id, amount)
                //checkERC1155Received(caller(), 0x0, account, id, amount, dataOffset)
            }

            function addBalance(account, id, amount) {
                let currentBalance := balanceOf(account, id)
                let storageLocation := getBalanceStorageLocation(account, id)
                sstore(storageLocation, add(currentBalance, amount))
            }

            function balanceOf(account, id) -> b {
                mstore(0x00, account)
                mstore(0x20, id)
                b := sload(keccak256(0x00, 0x40))
            }

            /* ---------- calldata decoding functions ----------- */
            function getSelector() -> s {
                // copy first 4 bytes from calldata
                // we do this by loading 32 bytes from calldata starting at position 0
                // then we shift right by 28 bytes (= 8 * 28 = 224 bits = 0xE0 bits)
                s := shr(0xE0, calldataload(0))
            }

            function decodeAddress(offset) -> v {
                v := decodeUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            function decodeUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                v := calldataload(pos)
            }

        }
    }
}