// deploy_scripts/main.ts

import "../hardhat.config";
import { ethers } from "hardhat";
import {
  ExPopulusCardGameLogic,
  ExPopulusCards,
  ExPopulusToken,
} from "../typechain";

export interface IDeployContractsOutput {
  exPopulusToken: ExPopulusToken;
  exPopulusCards: ExPopulusCards;
  exPopulusCardGameLogic: ExPopulusCardGameLogic;
}

export async function deployContracts(): Promise<IDeployContractsOutput> {
  const creator = (await ethers.getSigners())[0];

  const exPopulusCardsContract = await ethers.deployContract(
    "ExPopulusCards",
    creator,
  );
  await exPopulusCardsContract.deployed();

  const exPopulusTokenContract = await ethers.deployContract(
    "ExPopulusToken",
    [creator.address, exPopulusCardsContract.address], // Pass the address of ExPopulusCards as the constructor argument
    creator,
  );
  await exPopulusTokenContract.deployed();

  const exPopulusCardGameLogicContract = await ethers.deployContract(
    "ExPopulusCardGameLogic",
    creator,
  );
  await exPopulusCardGameLogicContract.deployed();

  return {
    exPopulusToken: exPopulusTokenContract as ExPopulusToken,
    exPopulusCards: exPopulusCardsContract as ExPopulusCards,
    exPopulusCardGameLogic:
      exPopulusCardGameLogicContract as ExPopulusCardGameLogic,
  };
}
