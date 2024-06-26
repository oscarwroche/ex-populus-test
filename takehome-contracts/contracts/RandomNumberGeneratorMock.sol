// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RandomNumberGeneratorMock {
    function generate(uint256 i) external view returns (uint256) {
        return i;
    }

    function generateRoulette() external view returns (uint256) {
        return 1;
    }
}
