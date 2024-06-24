// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "hardhat/console.sol";
import "./ExPopulusCards.sol";
import "./ExPopulusToken.sol";

contract ExPopulusCardGameLogic {
    ExPopulusCards public cardsContract;
    mapping(address => uint256) private winStreaks;

    struct ExtendedCard {
	ExPopulusCards.Card card;
	int256 currentHealth;
	bool hasUsedAbility;
	bool isShielded;
	bool isFrozen;
	bool wins;
    }

    constructor(address cardsContractAddress) {
        cardsContract = ExPopulusCards(cardsContractAddress);
    }

    function battle(address player, uint256[] calldata playerCardIds) external {
        require(playerCardIds.length == 3, "Must submit 3 cards");

        // Get enemy card IDs
        uint256[] memory enemyCardIds = cardsContract.getRandomCardIds(3);

        // Verify abilities have priorities set
        for (uint8 i = 0; i < 3; i++) {
            require(cardsContract.getAbilityPriority(i) != 0, "Ability priority not set");
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
		uint8 playerAbilityPriority = cardsContract.getAbilityPriority(extendedPlayerCard.card.ability);
		uint8 enemyAbilityPriority = cardsContract.getAbilityPriority(extendedEnemyCard.card.ability);

		console.log(extendedPlayerCard.card.health, extendedEnemyCard.card.health);

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
			processAbility(extendedEnemyCard, extendedPlayerCard);
		    }
		    if (extendedEnemyCard.wins) {
			return false;
		    }
		    if (!extendedPlayerCard.hasUsedAbility) {
			processAbility(extendedPlayerCard, extendedEnemyCard);
		    }
		    if (extendedPlayerCard.wins) {
			return true;
		    }
		}
		processAttack(extendedPlayerCard, extendedEnemyCard);
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

	    resetExtendedCardStatus(extendedPlayerCard);
	    resetExtendedCardStatus(extendedEnemyCard);
        }
    }

    function initializeExtendedCard(uint256 cardId) internal returns (ExtendedCard memory){
	ExPopulusCards.Card memory card = cardsContract.getCardDetails(cardId);
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
		if (block.timestamp % 10 == 0) {
		    firstPlayerCard.wins = true;
		}
	    } else if (playerAbility == 1 && !secondPlayerCard.isShielded) {
		// Frozen
		secondPlayerCard.isFrozen = true;
	    }
	}
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
