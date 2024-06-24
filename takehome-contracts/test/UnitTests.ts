import hre from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Signers } from "../types";
import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
import { deployContracts } from "../deploy_scripts/main";

describe("Unit tests - #1/#2", function () {
  before(async function () {
    chai.should();
    chai.use(chaiAsPromised);

    // Set up a signer for easy use
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.creator = signers[0];
    this.signers.testAccount2 = signers[1];
    this.signers.testAccount3 = signers[2];

    // Deploy the contracts
    this.contracts = await deployContracts();
  });

  describe("User Story #1 (Minting)", async function () {
    it("Can mint a card to a specific player & verify ownership afterwards", async function () {
      const { exPopulusCards } = this.contracts;

      const mintTx = await exPopulusCards
        .connect(this.signers.creator)
        .mintToken(this.signers.testAccount2.address, 100, 50, 1);

      await mintTx.wait();

      const cardDetails = await exPopulusCards.getCardDetails(0);

      expect(cardDetails.id).to.equal(0);
      expect(cardDetails.health).to.equal(100);
      expect(cardDetails.attack).to.equal(50);
      expect(cardDetails.ability).to.equal(1);
    });

    it("Only owner or approved minters can mint cards", async function () {
      const { exPopulusCards } = this.contracts;

      await expect(
        exPopulusCards
          .connect(this.signers.testAccount2)
          .mintToken(this.signers.testAccount2.address, 100, 50, 1),
      ).to.be.rejectedWith("Not authorized to mint");

      // Approve testAccount2 as a minter in the token contract
      const approveTx = await exPopulusCards
        .connect(this.signers.creator)
        .approveMinter(this.signers.testAccount2.address);

      await approveTx.wait();

      const mintTx = await exPopulusCards
        .connect(this.signers.testAccount2)
        .mintToken(this.signers.testAccount3.address, 90, 45, 2);

      await mintTx.wait();

      const cardDetails = await exPopulusCards.getCardDetails(1);

      expect(cardDetails.id).to.equal(1);
      expect(cardDetails.health).to.equal(90);
      expect(cardDetails.attack).to.equal(45);
      expect(cardDetails.ability).to.equal(2);
    });

    it("Cannot mint a card with an invalid ability", async function () {
      const { exPopulusCards } = this.contracts;

      await expect(
        exPopulusCards
          .connect(this.signers.creator)
          .mintToken(this.signers.testAccount2.address, 100, 50, 3),
      ).to.be.rejectedWith("Ability value must be 0, 1, or 2");
    });
  });

  describe("User Story #2 (Ability Configuration)", async function () {
    it("Can set and get ability priorities", async function () {
      const { exPopulusCards } = this.contracts;

      // Set priorities without conflict
      const setPriorityTx1 = await exPopulusCards
        .connect(this.signers.creator)
        .setAbilityPriority(0, 4); // Shield to priority 1
      await setPriorityTx1.wait();

      const setPriorityTx2 = await exPopulusCards
        .connect(this.signers.creator)
        .setAbilityPriority(1, 6); // Roulette to priority 0
      await setPriorityTx2.wait();

      const setPriorityTx3 = await exPopulusCards
        .connect(this.signers.creator)
        .setAbilityPriority(2, 7); // Freeze to priority 2
      await setPriorityTx3.wait();

      // Get priorities
      const priority0 = await exPopulusCards.getAbilityPriority(0);
      const priority1 = await exPopulusCards.getAbilityPriority(1);
      const priority2 = await exPopulusCards.getAbilityPriority(2);

      expect(priority0).to.equal(4);
      expect(priority1).to.equal(6);
      expect(priority2).to.equal(7);
    });

    it("Cannot set multiple abilities to the same priority", async function () {
      const { exPopulusCards } = this.contracts;

      // Set a valid priority
      const setPriorityTx = await exPopulusCards
        .connect(this.signers.creator)
        .setAbilityPriority(0, 1); // Shield to priority 1
      await setPriorityTx.wait();

      // Attempt to set another ability to the same priority
      await expect(
        exPopulusCards.connect(this.signers.creator).setAbilityPriority(1, 1), // Attempt to set Freeze to priority 1
      ).to.be.rejectedWith("Priority already assigned to another ability");
    });
  });
});

describe("Unit tests - #3", function () {
  before(async function () {
    chai.should();
    chai.use(chaiAsPromised);

    // Set up a signer for easy use
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.creator = signers[0];
    this.signers.testAccount2 = signers[1];
    this.signers.testAccount3 = signers[2];

    // Deploy the contracts with RNG mock
    this.contracts = await deployContracts(true);

    const { exPopulusCards } = this.contracts;

    const setPriorityTx1 = await exPopulusCards
      .connect(this.signers.creator)
      .setAbilityPriority(0, 4);
    await setPriorityTx1.wait();

    const setPriorityTx2 = await exPopulusCards
      .connect(this.signers.creator)
      .setAbilityPriority(1, 6);
    await setPriorityTx2.wait();

    const setPriorityTx3 = await exPopulusCards
      .connect(this.signers.creator)
      .setAbilityPriority(2, 7);
    await setPriorityTx3.wait();

    const { creator, testAccount2 } = this.signers;

    // Mint cards for the player
    await exPopulusCards
      .connect(creator)
      .mintToken(testAccount2.address, 100, 50, 1);
    await exPopulusCards
      .connect(creator)
      .mintToken(testAccount2.address, 80, 60, 0);
    await exPopulusCards
      .connect(creator)
      .mintToken(testAccount2.address, 90, 55, 2);
    await exPopulusCards
      .connect(creator)
      .mintToken(testAccount2.address, 100, 55, 1);
    await exPopulusCards
      .connect(creator)
      .mintToken(testAccount2.address, 90, 55, 0);
  });

  describe("User story #3 (Game loop)", async function () {
    it("Can run several battle and show a win streak for consecutive wins", async function () {
      const { exPopulusCards } = this.contracts;
      const { testAccount2 } = this.signers;

      // Run a battle
      await exPopulusCards.connect(testAccount2).battle([0, 2, 3]);
      await exPopulusCards.connect(testAccount2).battle([0, 2, 3]);
      await exPopulusCards.connect(testAccount2).battle([0, 2, 3]);

      // Check win streak
      const winStreak = await exPopulusCards
        .connect(testAccount2)
        .getWinStreak(testAccount2.address);

      expect(winStreak).to.equal(3); // We know the player always loses the first battle and wins the second and third since we mocked the RNG
    });

    it("Can run a battle and reset the win streak if it's lost", async function () {
      const { exPopulusCards } = this.contracts;
      const { testAccount2 } = this.signers;

      // Run a battle
      await exPopulusCards.connect(testAccount2).battle([0, 2, 4]);

      // Check win streak
      const winStreak = await exPopulusCards
        .connect(testAccount2)
        .getWinStreak(testAccount2.address);

      expect(winStreak).to.equal(0); // We know the player always loses the first battle and wins the second and third since we mocked the RNG
    });
  });

  // Other user stories can go here
});
