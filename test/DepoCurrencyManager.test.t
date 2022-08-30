import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { deployments, ethers, getNamedAccounts } from "hardhat";

import { DepoCurrencyManager } from "../typechain";

chai.use(solidity);

describe("DepoCurrencyManager", () => {
  let deployer: SignerWithAddress;
  let caller: SignerWithAddress;
  let currencyManager: DepoCurrencyManager;

  const EthAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
  const USDTAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
  const DEPOAddress = "0xa5DEf515cFd373D17830E7c1de1639cB3530a112";

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    caller = signers[1];

    const receipt: any = await deployments.deploy("DepoCurrencyManager", {
      from: deployer.address,
      args: [],
      log: true,
    });
    currencyManager = await ethers.getContractAt(
      "DepoCurrencyManager",
      receipt.address
    );
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {
      expect(await currencyManager.viewCountWhitelistedCurrencies()).to.eq(0);
    });
  });

  describe("addCurrency", async () => {
    it("currency should be added", async () => {
      await currencyManager.addCurrency(EthAddress);
      await currencyManager.addCurrency(USDTAddress);
      await currencyManager.addCurrency(DEPOAddress);
      expect(await currencyManager.viewCountWhitelistedCurrencies()).to.eq(3);
    });

    it("Currency: Already whitelisted", async () => {
      await expect(currencyManager.addCurrency(DEPOAddress)).to.be.reverted;
    });
  });

  describe("removeCurrency", async () => {
    it("currency should be removed", async () => {
      await currencyManager.removeCurrency(DEPOAddress);
      expect(await currencyManager.viewCountWhitelistedCurrencies()).to.eq(2);
    });

    it("Currency: Not whitelisted", async () => {
      await expect(currencyManager.removeCurrency(DEPOAddress)).to.be.reverted;
    });
  });

  describe("isCurrencyWhitelisted", async () => {
    it("currency should be in whitelist", async () => {
      expect(
        await currencyManager.isCurrencyWhitelisted(USDTAddress)
      ).to.be.equal(true);

      expect(
        await currencyManager.connect(caller).isCurrencyWhitelisted(EthAddress)
      ).to.be.equal(true);
    });

    it("currency shouldnot be in whitelist", async () => {
      expect(
        await currencyManager.connect(caller).isCurrencyWhitelisted(DEPOAddress)
      ).to.be.equal(false);
    });
  });

  describe("viewCountWhitelistedCurrencies", async () => {
    it("should be get count of WhitelistedCurrencies", async () => {
      expect(
        await currencyManager.connect(caller).viewCountWhitelistedCurrencies()
      ).to.eq(2);
    });
  });

  describe("viewWhitelistedCurrencies", async () => {
    it("should be get maximum currency list ", async () => {
      await currencyManager.addCurrency(DEPOAddress);
      const receipt = await currencyManager
        .connect(caller)
        .viewWhitelistedCurrencies(1, 3);
      expect(await receipt[1]).to.be.equal(3);
      expect(receipt[0][0]).to.be.equal(USDTAddress);
      expect(receipt[0][1]).to.be.equal(DEPOAddress);
    });

    it("should be get currency list", async () => {
      const receipt = await currencyManager
        .connect(caller)
        .viewWhitelistedCurrencies(0, 2);
      expect(await receipt[1]).to.be.equal(2);
      expect(receipt[0][0]).to.be.equal(EthAddress);
      expect(receipt[0][1]).to.be.equal(USDTAddress);
    });
  });
});
