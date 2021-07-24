// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//HID is inherting the ERC20 contract which has constructor with two arguments(name and symbol)
contract HIDToken is ERC20 {
    //setting this constructor to pass initial supply while deploying this contract (MyToken)
    constructor(uint256 initialSupply)
        
        ERC20("Hypersign Identity Token", "HID") //name and symbol
    {
        //mint function is called from inherited ERC20 contract
        //this mint function is used to add a initialSupply to the totalSupply of tokens
        //so totalSupply function will returns the amount of tokens in existence
        _mint(msg.sender, initialSupply);
     
    }
}
