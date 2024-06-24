// deploy_scripts/main.ts

import "../hardhat.config";
import { ethers } from "hardhat";
import { ExPopulusCards, ExPopulusToken } from "../typechain";

export interface IDeployContractsOutput {
  exPopulusToken: ExPopulusToken;
  exPopulusCards: ExPopulusCards;
}

export async function deployContracts(): Promise<IDeployContractsOutput> {
  const creator = (await ethers.getSigners())[0];

  const exPopulusCardsContract = await ethers.deployContract(
    "ExPopulusCards",
    [creator.address],
    creator,
  );
  await exPopulusCardsContract.deployed();

  const exPopulusTokenContract = await ethers.deployContract(
    "ExPopulusToken",
    [creator.address],
    creator,
  );
  await exPopulusTokenContract.deployed();

  return {
    exPopulusToken: exPopulusTokenContract as ExPopulusToken,
    exPopulusCards: exPopulusCardsContract as ExPopulusCards,
  };
}
