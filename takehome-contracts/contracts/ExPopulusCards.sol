// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import "./ExPopulusCardGameLogic.sol";

contract ExPopulusCards is ERC721, Ownable {
    struct Card {
        uint256 id;
        uint256 health;
        uint256 attack;
        uint8 ability;
    }

    mapping(uint256 => Card) private cards;
    mapping(uint8 => uint8) private abilityPriorities;

    uint256 private nextCardId;
    ExPopulusCards public cardsContract;
    ExPopulusCardGameLogic public cardGameLogicContract;
    mapping(address => bool) private approvedMinters;

    constructor(address initialOwner, address cardGameLogicContractAddress) ERC721("ExPopulusCardToken", "EPCT") Ownable(initialOwner) {
	cardGameLogicContract = ExPopulusCardGameLogic(cardGameLogicContractAddress);
	abilityPriorities[0] = 0; // Shield
        abilityPriorities[1] = 1; // Freeze
        abilityPriorities[2] = 2;
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
        for (uint256 i = 0; i < cardIds.length; i++) {
            require(ownerOf(cardIds[i]) == msg.sender, "Not the owner of the card");
            for (uint256 j = i + 1; j < cardIds.length; j++) {
                require(cardIds[i] != cardIds[j], "Duplicate card ID");
            }
        }
        cardGameLogicContract.battle(msg.sender, cardIds);
    }

    function createCard(uint256 health, uint256 attack, uint8 ability) external returns (uint256) {
        require(ability <= 2, "Ability value must be 0, 1, or 2");

	uint256 cardId = nextCardId++;

        cards[cardId] = Card({
            id: cardId,
            health: health,
            attack: attack,
            ability: ability
        });

	return cardId;
    }

    function getCardDetails(uint256 cardId) external view returns (Card memory) {
        require(cards[cardId].id == cardId, "Card does not exist");
        return cards[cardId];
    }

    function setAbilityPriority(uint8 abilityId, uint8 priority) external onlyOwner {
        require(abilityId <= 2, "Ability id must be 0, 1, or 2");
        for (uint8 i = 0; i <= 2; i++) {
            require(abilityPriorities[i] != priority, "Priority already assigned to another ability");
        }
        abilityPriorities[abilityId] = priority;
    }

    function getAbilityPriority(uint8 abilityId) external view returns (uint8) {
        require(abilityId <= 2, "Ability id must be 0, 1, or 2");
        return abilityPriorities[abilityId];
    }

    function getRandomCardIds(uint256 count) external view returns (uint256[] memory) {
        require(nextCardId >= count, "Not enough cards");
        uint256[] memory cardIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            cardIds[i] = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i))) % nextCardId;
        }
        return cardIds;
    }
}
