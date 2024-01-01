// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function withdraw(uint _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // transfer ether to another address
    function transfer(address payable _to, uint _amount) external onlyOwner {
        // 4.
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(_amount <= address(this).balance, "Insufficient balance");

        _to.transfer(_amount);
    }
}