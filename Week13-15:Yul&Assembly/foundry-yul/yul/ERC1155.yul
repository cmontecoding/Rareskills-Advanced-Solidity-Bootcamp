object "ERC1155" {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    code {
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        return(0, datasize("Runtime"))
    }

    /*//////////////////////////////////////////////////////////////
                                RUNTIME
    //////////////////////////////////////////////////////////////*/
    object "Runtime" {
        code {
            //Dispatcher
            switch getSelector()
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                let account := decodeAddress(0)
                let id := decodeUint(1)
                let amount := decodeUint(2)
                let dataOffset := decodeUint(3)

                _mint(account, id, amount, dataOffset)

                // emitTransferSingle(caller(), zeroAddress(), to, id, amount)
            }
            case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes) */{
                let account := decodeAddress(0)
                let idsOffset := decodeUint(1)
                let amountsOffset := decodeUint(2)
                let dataOffset := decodeUint(3)

                _mintBatch(account, idsOffset, amountsOffset, dataOffset)

                // emitTransferBatch(caller(), zeroAddress(), to, posIds, posAmounts)
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
                checkERC1155Received(caller(), 0x0, account, id, amount, dataOffset)
            }

            function _mintBatch(to, idsOffset, amountsOffset, dataOffset) {
                let idsLen := decodeUint(div(idsOffset, 0x20))
                let amountsLen := decodeUint(div(amountsOffset, 0x20))
                // checks array lengths match
                if iszero(eq(idsLen, amountsLen)) {
                    revert(0, 0)
                }

                let operator := caller()

                let idsStartPtr := add(idsOffset, 0x24)
                let amountsStartPtr := add(amountsOffset, 0x24)

                for { let i := 0 } lt(i, idsLen) { i := add(i, 1)}
                {
                    let id := calldataload(add(idsStartPtr, mul(0x20, i)))
                    let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))
                    addBalance(to, id, amount)
                }

                checkERC1155ReceivedBatch(operator, 0, to, idsOffset, amountsOffset, dataOffset)
            }

            function addBalance(account, id, amount) {
                let currentBalance := balanceOf(account, id)
                let storageLocation := getBalanceStorageLocation(account, id)
                sstore(storageLocation, add(currentBalance, amount))
            }

            function getBalanceStorageLocation(account, id) -> loc {
                let currentBalance := balanceOf(account, id)
                let offset := getFreeMemoryPointer()
                storeInMemory(account)
                storeInMemory(id)
                loc := keccak256(offset, 0x40)
            }
            
            function checkERC1155Received(operator, from, to, id, amount, dataOffset) {
            let size := extcodesize(to)
            if gt(size, 0) {
                // onERC1155Received(address,address,uint256,uint256,bytes)
                let onERC1155ReceivedSelector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000

                // abi encode arguments
                let offset := getFreeMemoryPointer()
                mstore(offset, onERC1155ReceivedSelector) // selector
                mstore(add(offset, 0x04), operator)       // operator
                mstore(add(offset, 0x24), from)           // from
                mstore(add(offset, 0x44), id)             // id
                mstore(add(offset, 0x64), amount)         // amount
                mstore(add(offset, 0x84), 0xa0)           // data

                let endPtr := copyBytesToMemory(add(offset, 0xa4), dataOffset) // Copies 'data' to memory
                setFreeMemoryPointer(endPtr)

                let argsOffset := offset
                let argsBytes := 0xa4
                let returnOffset := 0
                let returnBytes := 0x20
                // call(gas, address, argsOffset, argsSize, retOffset, retSize)
                let success := call(
                gas(), to, 0, offset, sub(endPtr, offset), 0x00, 0x04
                )
                if iszero(success) {
                revert(0, 0)
                }

                checkReturnValueIs(onERC1155ReceivedSelector)
            }
            }

            function checkERC1155ReceivedBatch(operator, from, to, idsOffset, amountsOffset, dataOffset) {
            if gt(extcodesize(to), 0) {
                /* onERC1155BatchReceived(address,address,uint256[],uint256[],bytes) */
                let onERC1155BatchReceivedSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000

                /* call onERC1155BatchReceived(operator, from, ids, amounts, data) */
                let oldMptr := mload(0x40)
                let mptr := oldMptr

                mstore(mptr, onERC1155BatchReceivedSelector)
                mstore(add(mptr, 0x04), operator)
                mstore(add(mptr, 0x24), from)
                mstore(add(mptr, 0x44), 0xa0)   // ids offset

                // mptr+0x44: idsOffset
                // mptr+0x64: amountsOffset
                // mptr+0x84: dataOffset
                // mptr+0xa4~: ids, amounts, data

                let amountsPtr := copyArrayToMemory(add(mptr, 0xa4), idsOffset) // copy ids to memory

                mstore(add(mptr, 0x64), sub(sub(amountsPtr, oldMptr), 4)) // amountsOffset
                let dataPtr := copyArrayToMemory(amountsPtr, amountsOffset) // copy amounts to memory

                mstore(add(mptr, 0x84), sub(sub(dataPtr, oldMptr), 4))       // dataOffset
                let endPtr := copyBytesToMemory(dataPtr, dataOffset)  // copy data to memory
                mstore(0x40, endPtr)

                // reverts if call fails
                mstore(0x00, 0) // clear memory
                let success := call(
                    gas(), to, 0, oldMptr, sub(endPtr, oldMptr), 0x00, 0x04
                )
                if iszero(success) {
                    revert(0, 0)
                }

                checkReturnValueIs(onERC1155BatchReceivedSelector)
            }
            }

            /*//////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
            //////////////////////////////////////////////////////////////*/

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

            /*//////////////////////////////////////////////////////////////
                                MEMORY MANAGEMENT
            //////////////////////////////////////////////////////////////*/

            function copyBytesToMemory(mptr, dataOffset) -> newMptr {
            let dataLenOffset := add(dataOffset, 4)
            let dataLen := calldataload(dataLenOffset)

            let totalLen := add(0x20, dataLen) // dataLen+data
            let rem := mod(dataLen, 0x20)
            if rem {
                totalLen := add(totalLen, sub(0x20, rem))
            }
            calldatacopy(mptr, dataLenOffset, totalLen)

            newMptr := add(mptr, totalLen)
            }

            function copyArrayToMemory(mptr, arrOffset) -> newMptr {
            let arrLenOffset := add(arrOffset, 4)
            let arrLen := calldataload(arrLenOffset)
            let totalLen := add(0x20, mul(arrLen, 0x20)) // len+arrData
            calldatacopy(mptr, arrLenOffset, totalLen) // copy len+data to mptr

            newMptr := add(mptr, totalLen)
            }

            function storeInMemory(value) {
            let offset := getFreeMemoryPointer()
            mstore(offset, value)
            setFreeMemoryPointer(add(offset, 0x20))
            }

            function getFreeMemoryPointer() -> p {
            p := mload(0x40)
            }

            function setFreeMemoryPointer(newPos) {
            mstore(0x40, newPos)
            }

            function initializeFreeMemoryPointer() {
            mstore(0x40, 0x80)
            }

            function checkReturnValueIs(expected) {
            let mptr := getFreeMemoryPointer()
            returndatacopy(mptr, 0x00, returndatasize())
            setFreeMemoryPointer(add(mptr, calldatasize()))
            let returnVal := mload(mptr)
            // revert if incorrect value is returned
            if iszero(eq(expected, returnVal)) {
                revert(0, 0)
            }
            }

        }
    }
}