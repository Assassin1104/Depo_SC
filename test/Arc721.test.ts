import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { zeroAddress } from "ethereumjs-util";
import { BigNumber, BigNumberish, BytesLike } from "ethers";
import { deployments, ethers, getNamedAccounts } from "hardhat";

import { Arc721 } from "../typechain";
import { MakerOrder, signMakeOrder } from "./utils/meta_transaction";

chai.use(solidity);

describe("Arc721", () => {
  let deployer: SignerWithAddress;
  let user1: SignerWithAddress;
  let user2: SignerWithAddress;

  let arc721: Arc721;

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    user1 = signers[1];
    user2 = signers[2];

    const receipt = await deployments.deploy("Arc721", {
      from: deployer.address,
      args: ["baseuri"],
      log: true,
    });
    arc721 = await ethers.getContractAt("Arc721", receipt.address);
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {});
  });

  describe("Arc721 Mint Now", async () => {
    it("single mint now", async () => {
      const r = await arc721.connect(user1).mint();
      expect(r).to.emit(arc721, "Transfer");
      const bal = await arc721.balanceOf(user1.address);
      expect(bal).to.be.eq(1);
    });

    it("batch mint now", async () => {
      await arc721.connect(user2).batchMint(5);
      const bal = await arc721.balanceOf(user2.address);
      expect(bal).to.be.eq(5);
    });
  });
});
