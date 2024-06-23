// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ExPopulusCards.sol";
import "./ExPopulusCardGameLogic.sol";
import "hardhat/console.sol";

contract ExPopulusToken is ERC721, Ownable {
    ExPopulusCards public cardsContract;
    ExPopulusCardGameLogic public cardGameLogicContract;
    mapping(address => bool) private approvedMinters;

    constructor(address initialOwner, address cardsContractAddress, address cardGameLogicContractAddress) ERC721("ExPopulusToken", "EPT") Ownable(initialOwner) {
	cardsContract = ExPopulusCards(cardsContractAddress);
	cardGameLogicContract = ExPopulusCardGameLogic(cardGameLogicContractAddress);
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

	uint256 tokenId = cardsContract.createCard(health, attack, ability);
        _mint(to, tokenId);
    }

    function battle(uint256[] calldata cardIds) external {
	console.log("SOL DEBUG", cardIds[0], cardIds[1], cardIds[2]);
	console.log("SOL DEBUG", ownerOf(cardIds[0]), ownerOf(cardIds[1]), ownerOf(cardIds[2]));
        for (uint256 i = 0; i < cardIds.length; i++) {
            require(ownerOf(cardIds[i]) == msg.sender, "Not the owner of the card");
            for (uint256 j = i + 1; j < cardIds.length; j++) {
                require(cardIds[i] != cardIds[j], "Duplicate card ID");
            }
        }
        cardGameLogicContract.battle(msg.sender, cardIds);
    }
}
