// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExPopulusCards.sol";
import "./ExPopulusCardGameLogic.sol";
import "hardhat/console.sol";

contract ExPopulusToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("ExPopulusToken", "EPT") Ownable(initialOwner) {}
}
