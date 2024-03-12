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
            initializeFreeMemoryPointer()

            //Dispatcher
            switch getSelector()
            case 0x731133e9 /* mint(address,uint256,uint256,bytes) */ {
                let account := decodeAddress(0)
                let id := decodeUint(1)
                let amount := decodeUint(2)
                let dataOffset := decodeUint(3)

                _mint(account, id, amount, dataOffset)

                emitTransferSingle(caller(), zeroAddress(), account, id, amount)
            }
            case 0xb48ab8b6 /* batchMint(address,uint256[],uint256[],bytes) */{
                let account := decodeAddress(0)
                let idsOffset := decodeUint(1)
                let amountsOffset := decodeUint(2)
                let dataOffset := decodeUint(3)

                batchMint(account, idsOffset, amountsOffset, dataOffset)

                emitTransferBatch(caller(), zeroAddress(), account, idsOffset, amountsOffset)
            }
            case 0xf5298aca /* burn(address,uint256,uint256) */ {
                let account := decodeAddress(0)
                let id := decodeUint(1)
                let amount := decodeUint(2)

                burn(account, id, amount)

                emitTransferSingle(caller(), account, zeroAddress(), id, amount)
            }
            case 0xf6eb127a /* burnBatch(address,uint256[],uint256[]) */ {
                let account := decodeAddress(0)
                let idsOffset := decodeUint(1)
                let amountsOffset := decodeUint(2)

                batchBurn(account, idsOffset, amountsOffset)

                emitTransferBatch(caller(), account, zeroAddress(), idsOffset, amountsOffset)
            }
            case 0x00fdd58e /* "balanceOf(address,uint256)" */ {
                let account := decodeAddress(0)
                let id := decodeUint(1)

                returnUint(balanceOf(account, id))
            }
            case 0x4e1273f4 /* "balanceOfBatch(address[],uint256[])" */ {
                let accountsOffset := decodeUint(0)
                let idsOffset := decodeUint(1)

                returnArray(balanceOfBatch(accountsOffset, idsOffset))
            }
            case 0xf242432a /* "safeTransferFrom(address,address,uint256,uint256,bytes)" */ {
                let from := decodeAddress(0)
                let to := decodeAddress(1)
                let id := decodeUint(2)
                let amount := decodeUint(3)
                let dataOffset := decodeUint(4)

                safeTransferFrom(from, to, id, amount, dataOffset)

                emitTransferSingle(caller(), from, to, id, amount)
            }
            case 0x2eb2c2d6 /* "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)" */ {
                let from := decodeAddress(0)
                let to := decodeAddress(1)
                let idsOffset := decodeUint(2)
                let amountsOffset := decodeUint(3)
                let dataOffset := decodeUint(4)

                safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset)

                emitTransferBatch(caller(), from, to, idsOffset, amountsOffset)

            }
            case 0xa22cb465 /* "setApprovalForAll(address,bool)" */ {
                let operator := decodeAddress(0)
                let approved := decodeUint(1)

                setApprovalForAll(operator, approved)

                emitApprovalForAll(caller(), operator, approved)
            }
            case 0xe985e9c5 /* "isApprovedForAll(address,address)" */ {
                let account := decodeAddress(0)
                let operator := decodeAddress(1)

                returnUint(isApprovedForAll(account, operator))
            }
            default {
                revert(0, 0)
            }

            /**
             * =============================================
             * EVENTS
             * =============================================
             */
            /// @dev TransferSingle(operator, from, to, id, amount)
            function emitTransferSingle(operator, from, to, id, amount) {
                let signatureHash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                // store the non-indexed data in memory to emit
                mstore(0x00, id)
                mstore(0x20, amount)

                log4(0x00, 0x40, signatureHash, operator, from, to)
            }

            /// @dev TransferBatch(operator, from, to, ids, amounts)
            function emitTransferBatch(operator, from, to, posIds, posAmounts) {
                let signatureHash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                
                let lenIds := decodeUint(div(posIds, 0x20))
                let lenAmounts := decodeUint(div(posAmounts, 0x20))

                let idsStart := 0x40
                let amountsStart := add(mul(0x20, lenIds), 0x60)

                // now start the amounts array, start with the length
                let totalSize := add(0x80, mul(mul(lenIds, 2), 0x20))

                // two dynamic arrays, store their starts in the first 2 slots
                mstore(0x00, idsStart) // ids start at 0x40
                mstore(0x20, amountsStart) // amounts start here; (len) * 0x20 + 0x60 = 3 * 0x20 + 0x60 = 0x120
                // now store the ids array, start with the length
                mstore(idsStart, lenIds)
                mstore(amountsStart, lenAmounts)

                // fill in the id values
                for { let i := 0 } lt(i, lenIds) { i:= add(i, 1) }
                {
                    let ithId := decodeUint(_getArrayElementSlot(posIds, i))
                    let ithAmount := decodeUint(_getArrayElementSlot(posAmounts, i))

                    mstore(add(add(idsStart, 0x20), mul(i, 0x20)), ithId)
                    mstore(add(add(amountsStart, 0x20), mul(i, 0x20)), ithAmount)
                }
                
                log4(0x00, totalSize, signatureHash, operator, from, to)
            }

            function emitApprovalForAll(_owner, operator, approved) {
                let signatureHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31
                mstore(0x00, approved)
                log3(0x00, 0x20, signatureHash, _owner, operator)
            }

            function _mint(account, id, amount, dataOffset) {
                // revert if minting to zero address
                if eq(account, 0) {
                    revert(0, 0)
                }
                addBalance(account, id, amount)
                checkERC1155Received(caller(), 0x0, account, id, amount, dataOffset)
            }

            function batchMint(to, idsOffset, amountsOffset, dataOffset) {
                if iszero(to) {
                    revert(0, 0)
                }
                
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

            function burn(account, id, amount) {
                let val := balanceOf(account, id)
                // revert if insufficient balance
                if gt(amount, val) {
                    revert(0, 0)
                }
                subBalance(account, id, amount)
            }

            function batchBurn(from, idsOffset, amountsOffset) {
            if iszero(from) {
                revert(0, 0)
            }

            let idsLen := decodeUint(div(idsOffset, 0x20))
            let amountsLen := decodeUint(div(amountsOffset, 0x20))

            // array lenghts must match
            if iszero(eq(idsLen, amountsLen)) {
                revert(0, 0)
            }

            let operator := caller()

            let idsStartPtr := add(idsOffset, 0x24)
            let amountsStartPtr := add(amountsOffset, 0x24)

            for { let i:= 0 } lt(i, idsLen) { i := add(i, 1)}
            {
                let id := calldataload(add(idsStartPtr, mul(0x20, i)))
                let amount := calldataload(add(amountsStartPtr, mul(0x20, i)))

                let fromBalance := balanceOf(from, id)

                if lt(fromBalance, amount) {
                    revert(0, 0)
                }
                subBalance(from, id, amount)
            }
            }

            function safeTransferFrom(from, to, id, amount, dataOffset) {
            // don't allow sending to zero address
            if iszero(to) {
                revert(0, 0)
            }

            transferTokens(from, to, id, amount)

            checkERC1155Received(caller(), from, to, id, amount, dataOffset) 
            }

            function safeBatchTransferFrom(from, to, idsOffset, amountsOffset, dataOffset) {
            // don't allow sending to zero address
            if iszero(to) {
                revert(0, 0)
            }

            let idsLen := decodeUint(div(idsOffset, 0x20))
            let amountsLen := decodeUint(div(amountsOffset, 0x20))

            // check lengths are the same
            if iszero(eq(idsLen, amountsLen)) {
                revert(0, 0)
            }

            for { let i := 0 } lt(i, idsLen) { i := add(i, 1) } {
                let id := decodeElementAtIndex(idsOffset, i)
                let amount := decodeElementAtIndex(amountsOffset, i)
                transferTokens(from, to, id, amount)
            }

            checkERC1155ReceivedBatch(caller(), from, to, idsOffset, amountsOffset, dataOffset)
            }

            function setApprovalForAll(operator, approved) {
            let slot := getOperatorApprovedSlot(caller(), operator)
            sstore(slot, approved)
            }

            function subBalance(account, id, amount) {
                let currentBalance := balanceOf(account, id)
                let storageLocation := getBalanceStorageLocation(account, id)
                sstore(storageLocation, sub(currentBalance, amount))
            }

            function addBalance(account, id, amount) {
                let currentBalance := balanceOf(account, id)
                let storageLocation := getBalanceStorageLocation(account, id)
                sstore(storageLocation, add(currentBalance, amount))
            }

            function transferTokens(from, to, id, amount) {
                let val := balanceOf(from, id)
                // revert if insufficient balance
                if gt(amount, val) {
                revert(0, 0)
                }
                subBalance(from, id, amount)
                addBalance(to, id, amount)
            }

            function getBalanceStorageLocation(account, id) -> loc {
                let currentBalance := balanceOf(account, id)
                let offset := getFreeMemoryPointer()
                storeInMemory(account)
                storeInMemory(id)
                loc := keccak256(offset, 0x40)
            }

            function getOperatorApprovedSlot(account, operator) -> slot {
            let offset := getFreeMemoryPointer()
            storeInMemory(account)
            storeInMemory(operator)
            slot := keccak256(offset, 0x40)
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

            function isApprovedForAll(account, operator) -> approved {
            let slot := getOperatorApprovedSlot(account, operator)
            approved := sload(slot)
            }

            function balanceOf(account, id) -> b {
                mstore(0x00, account)
                mstore(0x20, id)
                b := sload(keccak256(0x00, 0x40))
            }

            function balanceOfBatch(accountsOffset, idsOffset) -> balancesPtr {
            balancesPtr := getFreeMemoryPointer()

            let accountsLen := decodeUint(div(accountsOffset, 0x20))
            let idsLen := decodeUint(div(idsOffset, 0x20))

            // array lengths must match
            if iszero(eq(accountsLen, idsLen)) {
                revert(0,0)
            }

            storeInMemory(0x20) // array offset
            storeInMemory(accountsLen) // array length

            for { let i := 0 } lt(i, accountsLen) { i := add(i, 1) } {
                let account := decodeElementAtIndex(accountsOffset, i)
                let id := decodeElementAtIndex(idsOffset, i)
                let val := balanceOf(account, id)
                storeInMemory(val)
            }
            }

            /*//////////////////////////////////////////////////////////////
                                    ABI DECODING
            //////////////////////////////////////////////////////////////*/

            function decodeElementAtIndex(arrayOffset, index) -> element {
            let lengthOffset := add(4, arrayOffset)
            let firstElementOffset := add(lengthOffset, 0x20)
            let elementOffset := add(firstElementOffset, mul(index, 0x20))
            element := calldataload(elementOffset)
            }

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
                                        ENCODING
            //////////////////////////////////////////////////////////////*/

            function returnUint(v) {
            mstore(0, v)
            return(0, 0x20)
            }

            function returnArray(mptr) {
            let offset := mload(mptr)
            let len := mload(add(mptr, offset))
            let numBytes := add(mul(len, 0x20), 0x40)
            return(mptr, numBytes)
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

            /// @notice return the chunk index into the calldata where this dynamic array `posArr`'s ith element is stored.
            /// @notice example: this function returns 4. This means that decodeAsUint(4) returns the integer stored as the 5th word of the calldata (indices start at 0)
            /// @dev the returned integer `calldataSlotOffset` from this function can be used with decodeAs<X>(calldataSlotOffset) functions
            function _getArrayElementSlot(posArr, i) -> calldataSlotOffset {
                // We're asking: how many 32-byte chunks into the calldata does this array's ith element lie
                // the array itself starts at posArra (starts meaning: that is where the pointer to the length of the array is stored)
                let startingOffset := div(safeAdd(posArr, 0x20), 0x20)
                calldataSlotOffset := safeAdd(startingOffset, i)
            }

            function safeAdd(a, b) -> r {
                r := add(a, b)
                if or(lt(r, a), lt(r, b)) { revert(0, 0) }
            }

            /// @dev returns the zero address
            function zeroAddress() -> z {
                z := 0x0000000000000000000000000000000000000000000000000000000000000000
            }

        }
    }
}