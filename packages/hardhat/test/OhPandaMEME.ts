import { expect } from "chai";
import { ethers } from "hardhat";
import { OhPandaMEME } from "../typechain-types";

describe("OhPandaMEME", function () {
  // We define a fixture to reuse the same setup in every test.

  let ohPandaMEME: OhPandaMEME;
  before(async () => {
    const [owner] = await ethers.getSigners();
    const ohPandaMEMEFactory = await ethers.getContractFactory("OhPandaMEME");
    ohPandaMEME = (await ohPandaMEMEFactory.deploy()) as OhPandaMEME;
    await ohPandaMEME.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should have the right name on deploy", async function () {
      expect(await ohPandaMEME.name()).to.equal("OhPandaMEME");
    });
  });
});
