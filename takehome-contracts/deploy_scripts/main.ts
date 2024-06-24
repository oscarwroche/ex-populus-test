// deploy_scripts/main.ts

import "../hardhat.config";
import { ethers } from "hardhat";
import { ExPopulusCards, ExPopulusToken } from "../typechain";

export interface IDeployContractsOutput {
  exPopulusToken: ExPopulusToken;
  exPopulusCards: ExPopulusCards;
}

export async function deployContracts(
  mockRng?: boolean,
): Promise<IDeployContractsOutput> {
  const creator = (await ethers.getSigners())[0];

  const randomNumberGenerator = await ethers.deployContract(
    mockRng ? "RandomNumberGeneratorMock" : "RandomNumberGenerator",
    creator,
  );

  const exPopulusTokenContract = await ethers.deployContract(
    "ExPopulusToken",
    [creator.address],
    creator,
  );
  await exPopulusTokenContract.deployed();

  const exPopulusCardsContract = await ethers.deployContract(
    "ExPopulusCards",
    [
      creator.address,
      exPopulusTokenContract.address,
      randomNumberGenerator.address,
    ],
    creator,
  );
  await exPopulusCardsContract.deployed();

  await exPopulusTokenContract
    .connect(creator)
    .setAuthorizedMinter(exPopulusCardsContract.address);

  return {
    exPopulusToken: exPopulusTokenContract as ExPopulusToken,
    exPopulusCards: exPopulusCardsContract as ExPopulusCards,
  };
}
