// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract EtherWallet {
    address payable public owner;
    // Create a mapping for recoding if it is the member in whitelist or not
    mapping(address => bool) public whitelist;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        // midifier only the mambers' bool value are true in whitelist can send Ether
        require(whitelist[msg.sender], "Only whitelisted addresses can send Ether");
    }

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

    // Add an address to the whitelist and only the owner can add the address
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
    }

    // Remove an address from the whitelist and only the owner can remove the address
    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }
    
}