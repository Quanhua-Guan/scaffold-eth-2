import { expect } from "chai";
import { ethers } from "hardhat";
import { FutureRandom } from "../typechain-types";

describe("FutureRandom", function () {
  // We define a fixture to reuse the same setup in every test.

  let futureRandom: FutureRandom;
  before(async () => {
    const [owner] = await ethers.getSigners();
    const futureRandomFactory = await ethers.getContractFactory("FutureRandom");
    futureRandom = (await futureRandomFactory.deploy(owner.address)) as FutureRandom;
    await futureRandom.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should have the right 'blocksToWait'", async function () {
      expect(await futureRandom.blocksToWait).to.equal(10);
    });
  });
});
