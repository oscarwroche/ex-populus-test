// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExPopulusCards.sol";

contract ExPopulusToken is ERC721, Ownable {
    ExPopulusCards public cardsContract;
    uint256 private nextTokenId;
    mapping(address => bool) private approvedMinters;

    constructor(address initialOwner, address cardsContractAddress) ERC721("ExPopulusToken", "EPT") Ownable(initialOwner) {
	cardsContract = ExPopulusCards(cardsContractAddress);
    }

    function approveMinter(address minter) external onlyOwner {
	approvedMinters[minter] = true;
    }

    function revokeMinter(address minter) external onlyOwner {
	approvedMinters[minter] = false;
    }

    function mintToken(address to, uint256 health, uint256 attack, uint8 ability) public {
	require(msg.sender == owner() || approvedMinters[msg.sender], "Not authorized to mint");
        require(ability <= 2, "Ability value must be 0, 1, or 2");

        uint256 tokenId = nextTokenId++;
        _mint(to, tokenId);
        cardsContract.createCard(tokenId, health, attack, ability);
    }
}
