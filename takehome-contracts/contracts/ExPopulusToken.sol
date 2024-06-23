// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";

contract ExPopulusToken {
    ExPopulusCards public cardsContract;
    address public owner;
    mapping(address => bool) private approvedMinters;

    event MinterApproved(address indexed minter);
    event MinterRevoked(address indexed minter);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyOwnerOrApproved() {
        require(msg.sender == owner || approvedMinters[msg.sender], "Not authorized to mint");
        _;
    }

    constructor(address _cardsContractAddress) {
        cardsContract = ExPopulusCards(_cardsContractAddress);
        owner = msg.sender;
    }

    function approveMinter(address minter) external onlyOwner {
        approvedMinters[minter] = true;
        emit MinterApproved(minter);
    }

    function revokeMinter(address minter) external onlyOwner {
        approvedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    function mintToken(address to, uint256 health, uint256 attack, uint8 ability) external onlyOwnerOrApproved {
        cardsContract.mintCard(to, health, attack, ability);
    }

    function setAbilityPriority(uint8 abilityId, uint8 priority) external onlyOwnerOrApproved {
        cardsContract.setAbilityPriority(abilityId, priority);
    }
}
