import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { deployments, ethers, getNamedAccounts } from "hardhat";

import {
  DepoCurrencyManager,
  DepoExchange,
  DepoExecutionManager,
  DepoRoyaltyFeeManager,
  DepoTransferSelectorNFT,
  RoyaltyFeeRegistry,
  StrategyAnyItemFromCollectionForFixedPrice,
  StrategyPrivateSale,
  StrategyStandardSaleForFixedPrice,
  TransferManagerERC1155,
  TransferManagerERC721,
} from "../typechain";

chai.use(solidity);

describe("TransferSelectorNFT", () => {
  let deployer: SignerWithAddress;
  let caller: SignerWithAddress;

  let depoExchange: DepoExchange;
  let currencyManager: DepoCurrencyManager;
  let executionManager: DepoExecutionManager;

  let strategyStandardSaleForFixedPrice: StrategyStandardSaleForFixedPrice;
  let strategyAnyItemFromCollectionForFixedPrice: StrategyAnyItemFromCollectionForFixedPrice;
  let strategyPrivateSale: StrategyPrivateSale;

  let royaltyFeeManager: DepoRoyaltyFeeManager;
  let royaltyFeeRegistry: RoyaltyFeeRegistry;

  let transferManagerERC721: TransferManagerERC721;
  let transferManagerERC1155: TransferManagerERC1155;

  let transferSelectorNFT: DepoTransferSelectorNFT;

  const WETHAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
  const protocolFeeRecipientAddress =
    "0x5924A28caAF1cc016617874a2f0C3710d881f3c1";

  let TransferManagerERC721Address: string;
  let TransferManagerERC1155Address: string;

  const CollectionERC721Address = "0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D"; //
  const CollectionERC1155Address = "0x0546f6d538a2abf964ae4D537a131b226eBa9285";

  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    caller = signers[1];

    //deploy DepoCurrencyManager
    let receipt = await deployments.deploy("DepoCurrencyManager", {
      from: deployer.address,
      args: [],
      log: true,
    });
    currencyManager = await ethers.getContractAt(
      "DepoCurrencyManager",
      receipt.address
    );

    currencyManager.addCurrency(WETHAddress);

    //deploy DepoExecutionManager
    receipt = await deployments.deploy("DepoExecutionManager", {
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

    //deploy StrategyPrivateSale
    receipt = await deployments.deploy("StrategyPrivateSale", {
      from: deployer.address,
      args: [200],
      log: true,
    });
    strategyPrivateSale = await ethers.getContractAt(
      "StrategyPrivateSale",
      receipt.address
    );

    executionManager.addStrategy(strategyStandardSaleForFixedPrice.address);
    executionManager.addStrategy(
      strategyAnyItemFromCollectionForFixedPrice.address
    );
    executionManager.addStrategy(strategyPrivateSale.address);

    //deploy RoyaltyFeeRegistry
    receipt = await deployments.deploy("RoyaltyFeeRegistry", {
      from: deployer.address,
      args: [9500],
      log: true,
    });
    royaltyFeeRegistry = await ethers.getContractAt(
      "RoyaltyFeeRegistry",
      receipt.address
    );

    //deploy DepoRoyaltyFeeManager
    receipt = await deployments.deploy("DepoRoyaltyFeeManager", {
      from: deployer.address,
      args: [royaltyFeeRegistry.address],
      log: true,
    });
    royaltyFeeManager = await ethers.getContractAt(
      "DepoRoyaltyFeeManager",
      receipt.address
    );

    //deploy DepoExchange
    receipt = await deployments.deploy("DepoExchange", {
      from: deployer.address,
      args: [
        currencyManager.address,
        executionManager.address,
        royaltyFeeManager.address,
        WETHAddress,
        protocolFeeRecipientAddress,
      ],
      log: true,
    });
    depoExchange = await ethers.getContractAt("DepoExchange", receipt.address);

    receipt = await deployments.deploy("TransferManagerERC721", {
      from: deployer.address,
      args: [depoExchange.address],
      log: true,
    });
    transferManagerERC721 = await ethers.getContractAt(
      "TransferManagerERC721",
      receipt.address
    );

    TransferManagerERC721Address = transferManagerERC721.address;

    receipt = await deployments.deploy("TransferManagerERC1155", {
      from: deployer.address,
      args: [depoExchange.address],
      log: true,
    });
    transferManagerERC1155 = await ethers.getContractAt(
      "TransferManagerERC1155",
      receipt.address
    );

    TransferManagerERC1155Address = transferManagerERC1155.address;

    //deploy DepoTransferSelectorNFT
    receipt = await deployments.deploy("DepoTransferSelectorNFT", {
      from: deployer.address,
      args: [transferManagerERC721.address, transferManagerERC1155.address],
      log: true,
    });
    transferSelectorNFT = await ethers.getContractAt(
      "DepoTransferSelectorNFT",
      receipt.address
    );
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {
      expect(await transferSelectorNFT.INTERFACE_ID_ERC721()).to.eq(
        "0x80ac58cd"
      );
    });
  });

  describe("addCollectionTransferManager", async () => {
    it("Owner: Collection cannot be null address", async () => {
      await expect(
        transferSelectorNFT.addCollectionTransferManager(
          ZERO_ADDRESS,
          TransferManagerERC1155Address
        )
      ).to.be.reverted;
    });

    it("Owner: TransferManager cannot be null address", async () => {
      await expect(
        transferSelectorNFT.addCollectionTransferManager(
          CollectionERC721Address,
          ZERO_ADDRESS
        )
      ).to.be.reverted;
    });

    it("transferManagerSelectorForCollection should be updated", async () => {
      await transferSelectorNFT.addCollectionTransferManager(
        CollectionERC721Address,
        TransferManagerERC721Address
      );
      expect(
        await transferSelectorNFT.transferManagerSelectorForCollection(
          CollectionERC721Address
        )
      ).to.be.equal(TransferManagerERC721Address);
    });
  });

  describe("removeCollectionTransferManager", async () => {
    it("transferManagerSelectorForCollection should be set 0", async () => {
      await transferSelectorNFT.removeCollectionTransferManager(
        CollectionERC721Address
      );
      expect(
        await transferSelectorNFT.transferManagerSelectorForCollection(
          CollectionERC721Address
        )
      ).to.be.equal(ZERO_ADDRESS);
    });

    it("Owner: Collection has no transfer manager", async () => {
      await expect(
        transferSelectorNFT.removeCollectionTransferManager(
          CollectionERC721Address
        )
      ).to.be.reverted;
    });
  });

  describe("checkTransferManagerForToken", async () => {
    it("should be ERC721 tansfer manager", async () => {
      expect(
        await transferSelectorNFT
          .connect(caller)
          .checkTransferManagerForToken(CollectionERC721Address)
      ).to.be.equal(TransferManagerERC721Address);
    });
    it("should be ERC1155 tansfer manager", async () => {
      expect(
        await transferSelectorNFT
          .connect(caller)
          .checkTransferManagerForToken(CollectionERC1155Address)
      ).to.be.equal(TransferManagerERC1155Address);
    });
    it("should be got transfer manager address", async () => {
      await transferSelectorNFT.addCollectionTransferManager(
        CollectionERC721Address,
        TransferManagerERC1155Address
      );

      expect(
        await transferSelectorNFT
          .connect(caller)
          .checkTransferManagerForToken(CollectionERC721Address)
      ).to.be.equal(TransferManagerERC1155Address);
    });
  });
});
