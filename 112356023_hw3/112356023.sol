// SPDX-License-Identifier: MIT
// ERC20.sol
pragma solidity ^0.8.20;
import "./IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is IERC20, Ownable { 
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply; // 代幣總供給
    string public name; // 名稱
    string public symbol; // 符號
    uint8 public decimals = 18; // 小數位數

    constructor(string memory name_, string memory symbol_, address initialOwner) Ownable(initialOwner) {
        name = name_;
        symbol = symbol_;
    }

    // 實作`transfer`函數，代幣轉帳邏輯
    function transfer(address recipient, uint amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    // 實作 `approve` 函數, 代幣授權邏輯
    function approve(address spender, uint amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 實作`transferFrom`函數，代幣授權轉帳邏輯
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 鑄造代幣，從 `0` 地址轉帳給 呼叫者地址
    // Modify the `mint` function to allow only the owner to mint tokens
    function mint(uint amount) external onlyOwner {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    // 銷毀代幣，從 呼叫者地址 轉帳給 `0（0x00..000）` 地址
    function burn(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}

