// we are going to create a Multi-sig wallet
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Wallet{
    event Deposit(address indexed sender, uint amount, uint balance);   // what is the use of event keyword here?
    event SubmitTransaction (
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    
    event ConfirmTransaction (address indexed owner, uint indexed txIndex);
    event ExecuteTransaction (address indexed owner, uint indexed txIndex);
    event RevokeTransaction  (address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;  // checking if there is a duplicate owner by mapping
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;  // No. of owners that confirmed the txn.
    }

     // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) isConfirmed; // address of owners who confirms the txns.
    Transaction[] public transactions;

    // uint totalAmt;  // Total amount in wallet
    // address owner = msg.sender; 

    // Constructor that will initialize the state variables.
    constructor (address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");

        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "Invalid no. of required confirmations");
        for(uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");  // y samajh nahi aaya
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // Enabling this wallet to be able to receive ethers.
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

//  NOTE: helper function to easily deposit in remox
    function deposit() external payable  {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction is already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }
    // function deploy (owners, totalAmt, numConfirmationsRequired) view {

    // }

    function submitTransaction(address _to, uint _value, bytes memory data) 
    public onlyOwner 
    {  
        uint txIndex = transactions.length;

        transactions.push(Transaction({  // initializing the struct variable
            to: _to,
            value: _value,
            data: data,
            executed: false,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, data);
     }

    function confirmTransaction(uint _txIndex) 
        public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex) // owner will only be able to confirm a txn once.
    {
        Transaction storage transaction = transactions[_txIndex];

        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public 
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex]; // y ni samajh aaya

        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data); // nahi aaya samajh
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransaction(uint _txIndex) public 
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex) 
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "txn. not confirmed"); // y yaha kyu aaya ?

        isConfirmed[_txIndex][msg.sender] = false;
        transaction.numConfirmations -=1;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}


// owners
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]

// Address to send ether to 
// 0x583031D1113aD414F02576BD6afaBfb302140225