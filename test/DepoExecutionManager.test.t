import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { deployments, ethers, getNamedAccounts } from "hardhat";

import {
  DepoExecutionManager,
  StrategyAnyItemFromCollectionForFixedPrice,
  StrategyPrivateSale,
  StrategyStandardSaleForFixedPrice,
} from "../typechain";

chai.use(solidity);

describe("DepoExecutionManager", () => {
  let deployer: SignerWithAddress;
  let caller: SignerWithAddress;

  let executionManager: DepoExecutionManager;

  let strategyStandardSaleForFixedPrice: StrategyStandardSaleForFixedPrice;
  let strategyAnyItemFromCollectionForFixedPrice: StrategyAnyItemFromCollectionForFixedPrice;
  let strategyPrivateSale: StrategyPrivateSale;

  let StrategyStandardSaleForFixedPriceAddress: string;
  let StrategyAnyItemFromCollectionForFixedPriceAddress: string;
  let StrategyPrivateSaleAddress: string;

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    caller = signers[1];

    //deploy executionManager
    let receipt = await deployments.deploy("DepoExecutionManager", {
      from: deployer.address,
      args: [],
      log: true,
    });
    executionManager = await ethers.getContractAt(
      "DepoExecutionManager",
      receipt.address
    );

    //deploy StrategyStandardSaleForFixedPrice
    receipt = await deployments.deploy("StrategyStandardSaleForFixedPrice", {
      from: deployer.address,
      args: [200],
      log: true,
    });
    strategyStandardSaleForFixedPrice = await ethers.getContractAt(
      "StrategyStandardSaleForFixedPrice",
      receipt.address
    );

    StrategyStandardSaleForFixedPriceAddress =
      strategyStandardSaleForFixedPrice.address;

    //deploy StrategyAnyItemFromCollectionForFixedPrice
    receipt = await deployments.deploy(
      "StrategyAnyItemFromCollectionForFixedPrice",
      {
        from: deployer.address,
        args: [200],
        log: true,
      }
    );
    strategyAnyItemFromCollectionForFixedPrice = await ethers.getContractAt(
      "StrategyAnyItemFromCollectionForFixedPrice",
      receipt.address
    );

    StrategyAnyItemFromCollectionForFixedPriceAddress =
      strategyAnyItemFromCollectionForFixedPrice.address;

    //deploy StrategyPrivateSal
    receipt = await deployments.deploy("StrategyPrivateSale", {
      from: deployer.address,
      args: [200],
      log: true,
    });
    strategyPrivateSale = await ethers.getContractAt(
      "StrategyPrivateSale",
      receipt.address
    );

    StrategyPrivateSaleAddress = strategyPrivateSale.address;
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {
      expect(await executionManager.viewCountWhitelistedStrategies()).to.eq(0);
    });
  });

  describe("addStrategy", async () => {
    it("strategy should be added", async () => {
      await executionManager.addStrategy(
        StrategyStandardSaleForFixedPriceAddress
      );
      await executionManager.addStrategy(
        StrategyAnyItemFromCollectionForFixedPriceAddress
      );
      await executionManager.addStrategy(StrategyPrivateSaleAddress);
      expect(await executionManager.viewCountWhitelistedStrategies()).to.eq(3);
    });

    it("Strategy: Already whitelisted", async () => {
      await expect(
        executionManager.addStrategy(
          StrategyAnyItemFromCollectionForFixedPriceAddress
        )
      ).to.be.reverted;
    });
  });

  describe("removeStrategy", async () => {
    it("strategy should be removed", async () => {
      await executionManager.removeStrategy(StrategyPrivateSaleAddress);
      expect(await executionManager.viewCountWhitelistedStrategies()).to.eq(2);
    });

    it("Strategy: Not whitelisted", async () => {
      await expect(executionManager.removeStrategy(StrategyPrivateSaleAddress))
        .to.be.reverted;
    });
  });

  describe("isStrategyWhitelisted", async () => {
    it("strategy should be in whitelist", async () => {
      expect(
        await executionManager.isStrategyWhitelisted(
          StrategyStandardSaleForFixedPriceAddress
        )
      ).to.be.equal(true);

      expect(
        await executionManager
          .connect(caller)
          .isStrategyWhitelisted(
            StrategyAnyItemFromCollectionForFixedPriceAddress
          )
      ).to.be.equal(true);
    });

    it("strategy shouldnot be in whitelist", async () => {
      expect(
        await executionManager
          .connect(caller)
          .isStrategyWhitelisted(StrategyPrivateSaleAddress)
      ).to.be.equal(false);
    });
  });

  describe("viewCountWhitelistedStrategies", async () => {
    it("should be get count of whitelistedStrategies", async () => {
      expect(
        await executionManager.connect(caller).viewCountWhitelistedStrategies()
      ).to.eq(2);
    });
  });

  describe("viewWhitelistedStrategies", async () => {
    it("should be get maximum strategy list ", async () => {
      await executionManager.addStrategy(StrategyPrivateSaleAddress);
      const receipt = await executionManager
        .connect(caller)
        .viewWhitelistedStrategies(1, 3);
      expect(await receipt[1]).to.be.equal(3);
      expect(receipt[0][0]).to.be.equal(
        StrategyAnyItemFromCollectionForFixedPriceAddress
      );
      expect(receipt[0][1]).to.be.equal(StrategyPrivateSaleAddress);
    });

    it("should be get strategy list", async () => {
      const receipt = await executionManager
        .connect(caller)
        .viewWhitelistedStrategies(0, 2);
      expect(await receipt[1]).to.be.equal(2);
      expect(receipt[0][0]).to.be.equal(
        StrategyStandardSaleForFixedPriceAddress
      );
      expect(receipt[0][1]).to.be.equal(
        StrategyAnyItemFromCollectionForFixedPriceAddress
      );
    });
  });
});
