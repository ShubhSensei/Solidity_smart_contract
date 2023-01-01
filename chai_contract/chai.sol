//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

contract buychai{
    struct Transactions{
        string name;
        string message;
        uint256 timestamp;
        address sender;
    }

    Transactions[] transactions;

    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function buyChai(string memory name, string memory message) public payable {
        require(msg.value >0, "Please pay greater than 0 ether");
        owner.transfer(msg.value);
        transactions.push(Transactions(name, message, block.timestamp, msg.sender));
    }

    function getTransactions() public view returns (Transactions[] memory) {
        return transactions;
    }
    
}