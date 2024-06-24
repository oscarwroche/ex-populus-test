// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomNumberGenerator.sol";
import "hardhat/console.sol";

contract ExPopulusCards is ERC721, Ownable {
    struct Card {
        uint256 id;
        uint256 health;
        uint256 attack;
        uint8 ability;
    }

    struct ExtendedCard {
	ExPopulusCards.Card card;
	int256 currentHealth;
	bool hasUsedAbility;
	bool isShielded;
	bool isFrozen;
	bool wins;
    }

    uint256 private nextCardId;
    RandomNumberGenerator public randomNumberGeneratorContract;

    mapping(uint256 => Card) private cards;
    mapping(uint8 => uint8) private abilityPriorities;
    mapping(address => bool) private approvedMinters;
    mapping(address => uint256) private winStreaks;

    constructor(address initialOwner, address randomNumberGeneratorContractAddress) ERC721("ExPopulusCardToken", "EPCT") Ownable(initialOwner) {
	abilityPriorities[0] = 0; // Shield
        abilityPriorities[1] = 1; // Freeze
        abilityPriorities[2] = 2; // Roulette
	randomNumberGeneratorContract = RandomNumberGenerator(randomNumberGeneratorContractAddress);
    }

    function mintToken(address to, uint256 health, uint256 attack, uint8 ability) public {
	require(msg.sender == owner() || approvedMinters[msg.sender], "Not authorized to mint");
        require(ability <= 2, "Ability value must be 0, 1, or 2");

	uint256 tokenId = createCard(health, attack, ability);
        _mint(to, tokenId);
    }

    function approveMinter(address minter) external onlyOwner {
	approvedMinters[minter] = true;
    }

    function revokeMinter(address minter) external onlyOwner {
	approvedMinters[minter] = false;
    }

    function createCard(uint256 health, uint256 attack, uint8 ability) internal returns (uint256) {
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

    function battle(uint256[] calldata cardIds) external {
        for (uint256 i = 0; i < cardIds.length; i++) {
            require(ownerOf(cardIds[i]) == msg.sender, "Not the owner of the card");
            for (uint256 j = i + 1; j < cardIds.length; j++) {
                require(cardIds[i] != cardIds[j], "Duplicate card ID");
            }
        }
        battle(msg.sender, cardIds);
    }

    function getCardDetails(uint256 cardId) public view returns (Card memory) {
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

    function getAbilityPriority(uint8 abilityId) public view returns (uint8) {
        require(abilityId <= 2, "Ability id must be 0, 1, or 2");
        return abilityPriorities[abilityId];
    }

    // Game logic below

    function getRandomCardIds(uint256 count) internal returns (uint256[] memory) {
        require(nextCardId >= count, "Not enough cards");
        uint256[] memory cardIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            cardIds[i] = randomNumberGeneratorContract.generate(i) % nextCardId;
        }
        return cardIds;
    }

    function battle(address player, uint256[] calldata playerCardIds) internal {
        require(playerCardIds.length == 3, "Must submit 3 cards");

        // Get enemy card IDs
        uint256[] memory enemyCardIds = getRandomCardIds(3);

        // Verify abilities have priorities set
        for (uint8 i = 0; i < 3; i++) {
            require(getAbilityPriority(i) != 0, "Ability priority not set");
        }

        // Run the battle logic
        bool playerWins = runBattle(playerCardIds, enemyCardIds);

        // Update win streak
        updateWinStreak(player, playerWins);
    }

    function runBattle(uint256[] memory playerCardIds, uint256[] memory enemyCardIds) internal returns (bool) {
        uint8 playerFrontIndex = 0;
        uint8 enemyFrontIndex = 0;

	ExtendedCard memory extendedPlayerCard = initializeExtendedCard(playerCardIds[playerFrontIndex]);
	ExtendedCard memory extendedEnemyCard = initializeExtendedCard(enemyCardIds[enemyFrontIndex]);

        while (true) {
	    while (extendedPlayerCard.currentHealth > 0 && extendedEnemyCard.currentHealth > 0) {
		uint8 playerAbilityPriority = getAbilityPriority(extendedPlayerCard.card.ability);
		uint8 enemyAbilityPriority = getAbilityPriority(extendedEnemyCard.card.ability);

		console.log("front indices");
		console.log(playerFrontIndex, enemyFrontIndex);
		console.log("card attacks");
		console.log(extendedPlayerCard.card.attack, extendedEnemyCard.card.attack);
		console.log("card ability");
		console.log(extendedPlayerCard.card.ability, extendedEnemyCard.card.ability);
		console.log("current healths");
		console.logInt(extendedPlayerCard.currentHealth);
		console.logInt(extendedEnemyCard.currentHealth);
		console.log("has used ability");
		console.log(extendedPlayerCard.hasUsedAbility, extendedEnemyCard.hasUsedAbility);
		console.log("is shielded");
		console.log(extendedPlayerCard.isShielded, extendedEnemyCard.isShielded);
		console.log("is frozen");
		console.log(extendedPlayerCard.isFrozen, extendedEnemyCard.isFrozen);

		if (playerAbilityPriority >= enemyAbilityPriority) {
		    if (!extendedPlayerCard.hasUsedAbility) {
			(extendedPlayerCard, extendedEnemyCard) = processAbility(extendedPlayerCard, extendedEnemyCard);
		    }
		    if (extendedPlayerCard.wins) {
			return true;
		    }
		    if (!extendedEnemyCard.hasUsedAbility) {
			(extendedEnemyCard, extendedPlayerCard) = processAbility(extendedEnemyCard, extendedPlayerCard);
		    }
		    if (extendedEnemyCard.wins) {
			return false;
		    }
		} else {
		    if (!extendedEnemyCard.hasUsedAbility) {
			(extendedEnemyCard, extendedPlayerCard) = processAbility(extendedEnemyCard, extendedPlayerCard);
		    }
		    if (extendedEnemyCard.wins) {
			return false;
		    }
		    if (!extendedPlayerCard.hasUsedAbility) {
			(extendedPlayerCard, extendedEnemyCard) = processAbility(extendedPlayerCard, extendedEnemyCard);
		    }
		    if (extendedPlayerCard.wins) {
			return true;
		    }
		}
		(extendedPlayerCard, extendedEnemyCard) = processAttack(extendedPlayerCard, extendedEnemyCard);
		extendedPlayerCard = resetExtendedCardStatus(extendedPlayerCard);
	        extendedEnemyCard = resetExtendedCardStatus(extendedEnemyCard);
	    }

            if (extendedPlayerCard.currentHealth <= 0) {
                if (playerFrontIndex == 2) {
		    return false;
		} else {
		    playerFrontIndex++;
		    extendedPlayerCard = initializeExtendedCard(playerCardIds[playerFrontIndex]);
		}
            }
	    if (extendedEnemyCard.currentHealth <= 0) {
		if (enemyFrontIndex == 2) {
		    return true;
		} else {
		    enemyFrontIndex++;
		    extendedEnemyCard = initializeExtendedCard(playerCardIds[playerFrontIndex]);
		}
            }
        }
    }

    function initializeExtendedCard(uint256 cardId) internal returns (ExtendedCard memory){
	ExPopulusCards.Card memory card = getCardDetails(cardId);
	return ExtendedCard({card: card, currentHealth: int(card.health), hasUsedAbility: false, isShielded: false, isFrozen: false, wins: false});
    }

    function resetExtendedCardStatus(ExtendedCard memory extendedCard) internal returns (ExtendedCard memory) {
        return ExtendedCard({card: extendedCard.card, currentHealth: extendedCard.currentHealth, hasUsedAbility: extendedCard.hasUsedAbility, isShielded: false, isFrozen: false, wins: false});
    }

    function processAbility(ExtendedCard memory firstPlayerCard, ExtendedCard memory secondPlayerCard) internal returns (ExtendedCard memory, ExtendedCard memory) {
	uint8 playerAbility = firstPlayerCard.card.ability;
	if (!firstPlayerCard.isFrozen) {
	    // Shield
	    if (playerAbility == 0) {
		firstPlayerCard.isShielded = true;
	    } else if (playerAbility == 2) {
		// Roulette
		if (randomNumberGeneratorContract.generateRoulette() % 10 == 0) {
		    firstPlayerCard.wins = true;
		}
	    } else if (playerAbility == 1 && !secondPlayerCard.isShielded) {
		// Frozen
		secondPlayerCard.isFrozen = true;
	    }
	}
	firstPlayerCard.hasUsedAbility = true;
	return (firstPlayerCard, secondPlayerCard);
    }

    function processAttack(ExtendedCard memory firstPlayerExtendedCard, ExtendedCard memory secondPlayerExtendedCard) internal returns (ExtendedCard memory, ExtendedCard memory) {
	if (!firstPlayerExtendedCard.isFrozen && !secondPlayerExtendedCard.isShielded) {
	    secondPlayerExtendedCard.currentHealth -= int(firstPlayerExtendedCard.card.attack);
	}
	if (!secondPlayerExtendedCard.isFrozen && !firstPlayerExtendedCard.isShielded) {
	    firstPlayerExtendedCard.currentHealth -= int(secondPlayerExtendedCard.card.attack);
	}
	return (firstPlayerExtendedCard, secondPlayerExtendedCard);
    }

    function getWinStreak(address player) external view returns (uint256) {
        return winStreaks[player];
    }

    function updateWinStreak(address player, bool win) internal {
        if (win) {
            winStreaks[player]++;
        } else {
            winStreaks[player] = 0;
        }
    }
}
