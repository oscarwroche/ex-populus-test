// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract ExPopulusCards {
    struct Card {
        uint256 id;
        uint256 health;
        uint256 attack;
        uint8 ability;
    }

    uint256 private nextCardId;
    mapping(uint256 => Card) private cards;
    mapping(uint8 => uint8) private abilityPriorities;

    event CardMinted(uint256 indexed cardId, address indexed to, uint256 health, uint256 attack, uint8 ability);
    event AbilityPriorityUpdated(uint8 indexed abilityId, uint8 priority);

    constructor() {
        // Initialize default ability priorities: Shield > Freeze > Roulette
        abilityPriorities[0] = 0; // Shield
        abilityPriorities[1] = 1; // Freeze
        abilityPriorities[2] = 2; // Roulette
    }

    function mintCard(address to, uint256 health, uint256 attack, uint8 ability) external returns (uint256) {
        require(ability <= 2, "Ability value must be 0, 1, or 2");

        uint256 cardId = nextCardId++;
        cards[cardId] = Card({
            id: cardId,
            health: health,
            attack: attack,
            ability: ability
        });

        emit CardMinted(cardId, to, health, attack, ability);

        return cardId;
    }

    function getCardDetails(uint256 cardId) external view returns (Card memory) {
        require(cardId < nextCardId, "Card does not exist");
        return cards[cardId];
    }

    function setAbilityPriority(uint8 abilityId, uint8 priority) external {
        require(abilityId <= 2, "Ability id must be 0, 1, or 2");
        for (uint8 i = 0; i <= 2; i++) {
            require(abilityPriorities[i] != priority, "Priority already assigned to another ability");
        }
        abilityPriorities[abilityId] = priority;
        emit AbilityPriorityUpdated(abilityId, priority);
    }

    function getAbilityPriority(uint8 abilityId) external view returns (uint8) {
        require(abilityId <= 2, "Ability id must be 0, 1, or 2");
        return abilityPriorities[abilityId];
    }
}
