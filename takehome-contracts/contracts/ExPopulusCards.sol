// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ExPopulusCards {
    struct Card {
        uint256 id;
        uint256 health;
        uint256 attack;
        uint8 ability;
    }

    mapping(uint256 => Card) private cards;
    mapping(uint8 => uint8) private abilityPriorities;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
	owner = msg.sender;
        // Initialize default ability priorities: Shield > Freeze > Roulette
        abilityPriorities[0] = 0; // Shield
        abilityPriorities[1] = 1; // Freeze
        abilityPriorities[2] = 2; // Roulette
    }

    function createCard(uint256 cardId, uint256 health, uint256 attack, uint8 ability) external {
        require(ability <= 2, "Ability value must be 0, 1, or 2");

        cards[cardId] = Card({
            id: cardId,
            health: health,
            attack: attack,
            ability: ability
        });
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
}
