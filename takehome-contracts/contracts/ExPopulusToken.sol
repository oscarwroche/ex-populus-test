// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ExPopulusToken is ERC20, Ownable {
    address public authorizedMinter;

    constructor(address initialOwner) ERC20("ExPopulusToken", "EPT") Ownable(initialOwner) {}

    function setAuthorizedMinter(address newMinter) public onlyOwner {
	authorizedMinter = newMinter;
    }

    function mintToken(address to, uint256 quantity) public {
	require (msg.sender == authorizedMinter || msg.sender == owner(), "Address that is not owner or card contract is not allowed to mint");
	_mint(to, quantity);
    }
}
