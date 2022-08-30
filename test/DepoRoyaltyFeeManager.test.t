import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { deployments, ethers, getNamedAccounts } from "hardhat";

import { DepoRoyaltyFeeManager, RoyaltyFeeRegistry } from "../typechain";

chai.use(solidity);

describe("DepoRoyaltyFeeManager", () => {
  let deployer: SignerWithAddress;
  let caller: SignerWithAddress;

  let royaltyFeeRegistry: RoyaltyFeeRegistry;
  let royaltyFeeManager: DepoRoyaltyFeeManager;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    caller = signers[1];

    let receipt: any = await deployments.deploy("RoyaltyFeeRegistry", {
      from: deployer.address,
      args: [100],
      log: true,
    });
    royaltyFeeRegistry = await ethers.getContractAt(
      "RoyaltyFeeRegistry",
      receipt.address
    );

    receipt = await deployments.deploy("DepoRoyaltyFeeManager", {
      from: deployer.address,
      args: [royaltyFeeRegistry.address],
      log: true,
    });
    royaltyFeeManager = await ethers.getContractAt(
      "DepoRoyaltyFeeManager",
      receipt.address
    );
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {
      expect(await royaltyFeeManager.INTERFACE_ID_ERC2981()).to.eq(
        "0x2a55205a"
      );
    });
  });

  describe("calculateRoyaltyFeeAndGetRecipient", async () => {
    //IRoyaltyFeeRegistry Test
  });
});
