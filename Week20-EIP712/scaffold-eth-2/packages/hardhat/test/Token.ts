import { expect } from "chai";
import { ethers } from "hardhat";
import { YourContract } from "../typechain-types";

describe("Token", function () {
  // We define a fixture to reuse the same setup in every test.

  let yourContract: YourContract;
  before(async () => {
    const [owner] = await ethers.getSigners();
    const tokenFactory = await ethers.getContractFactory("Token");
    yourContract = (await tokenFactory.deploy(owner.address)) as YourContract;
    await yourContract.deployed();
  });

  describe("Deployment", function () {
    it("Should have the right name on deploy", async function () {
      expect(await yourContract.name()).to.equal("MyToken");
    });

    it("Should have the right symbol on deploy", async function () {
      expect(await yourContract.symbol()).to.equal("MT");
    });

    // it("Should allow setting a new message", async function () {
    //   const newGreeting = "Learn Scaffold-ETH 2! :)";

    //   await yourContract.setGreeting(newGreeting);
    //   expect(await yourContract.greeting()).to.equal(newGreeting);
    // });
  });
});