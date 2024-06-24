// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RandomNumberGenerator {
    function generate(uint256 i) external view returns (uint256) {
	return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)));
    }

    function generateRoulette() external view returns (uint256) {
	return block.timestamp;
    }
}
