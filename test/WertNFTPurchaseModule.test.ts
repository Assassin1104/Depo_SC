import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { BigNumber } from "ethers";
import { deployments, ethers } from "hardhat";

import {
  Arc721,
  DepoCurrencyManager,
  DepoExchange,
  DepoExecutionManager,
  DepoRoyaltyFeeManager,
  DepoTransferSelectorNFT,
  MockERC20,
  MockERC721,
  RoyaltyFeeRegistry,
  StrategyAnyItemFromCollectionForFixedPrice,
  StrategyPrivateSale,
  StrategyStandardSaleForFixedPrice,
  TransferManagerERC1155,
  TransferManagerERC721,
  WertNFTPurchaseModule,
} from "../typechain";
import { MakerOrder, signMakeOrder } from "./utils/meta_transaction";

chai.use(solidity);

describe("WertNFTPurchaseModule", () => {
  let deployer: SignerWithAddress;
  let caller: SignerWithAddress;
  let erc20Owner: SignerWithAddress;
  let erc721Owner: SignerWithAddress;

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

  let wertModule: WertNFTPurchaseModule;

  let erc20Token: MockERC20;
  let erc721Token: MockERC721;
  let arc721Token: Arc721;

  const protocolFeeRecipientAddress =
    "0x5924A28caAF1cc016617874a2f0C3710d881f3c1";

  before(async () => {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    caller = signers[1];
    erc20Owner = signers[2];
    erc721Owner = signers[3];

    let receipt = await deployments.deploy("MockERC20", {
      from: erc20Owner.address,
      args: ["MFT", "Mock ERC 20", 1000],
      log: true,
    });
    erc20Token = await ethers.getContractAt("MockERC20", receipt.address);

    receipt = await deployments.deploy("MockERC721", {
      from: deployer.address,
      args: ["MNFT", "Mock ERC 721"],
      log: true,
    });
    erc721Token = await ethers.getContractAt("MockERC721", receipt.address);

    receipt = await deployments.deploy("Arc721", {
      from: deployer.address,
      args: ["baseuri"],
      log: true,
    });
    arc721Token = await ethers.getContractAt("Arc721", receipt.address);

    await erc721Token.mint(erc721Owner.address, 1);
    await erc721Token.mint(erc721Owner.address, 2);
    await erc721Token.mint(erc721Owner.address, 3);
    await erc721Token.mint(erc721Owner.address, 4);

    //deploy DepoCurrencyManager
    receipt = await deployments.deploy("DepoCurrencyManager", {
      from: deployer.address,
      args: [],
      log: true,
    });
    currencyManager = await ethers.getContractAt(
      "DepoCurrencyManager",
      receipt.address
    );

    await currencyManager.addCurrency(erc20Token.address);

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

    await executionManager.addStrategy(
      strategyStandardSaleForFixedPrice.address
    );
    await executionManager.addStrategy(
      strategyAnyItemFromCollectionForFixedPrice.address
    );
    await executionManager.addStrategy(strategyPrivateSale.address);

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
        erc20Token.address,
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

    await arc721Token.addOperator(transferManagerERC721.address);

    receipt = await deployments.deploy("TransferManagerERC1155", {
      from: deployer.address,
      args: [depoExchange.address],
      log: true,
    });
    transferManagerERC1155 = await ethers.getContractAt(
      "TransferManagerERC1155",
      receipt.address
    );

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

    await depoExchange.updateTransferSelectorNFT(transferSelectorNFT.address);

    await erc20Token
      .connect(erc20Owner)
      .approve(
        depoExchange.address,
        await erc20Token.balanceOf(erc20Owner.address)
      );

    await erc721Token
      .connect(erc721Owner)
      .setApprovalForAll(transferManagerERC721.address, true);

    receipt = await deployments.deploy("WertNFTPurchaseModule", {
      from: deployer.address,
      args: [depoExchange.address],
      log: true,
    });
    wertModule = await ethers.getContractAt(
      "WertNFTPurchaseModule",
      receipt.address
    );
  });

  describe("deploy", async () => {
    it("should be deployed", async () => {});
  });

  describe("matchAskWithTakerBidUsingETHAndWETH", async () => {
    it("match should be confirmed for normal ERC721", async () => {
      const beforeBalance = await erc20Owner.getBalance();
      const ownerBeforeBalance = await erc721Owner.getBalance();
      const takeOrder = {
        isOrderAsk: false,
        taker: erc20Owner.address,
        price: 10,
        tokenId: 4,
        minPercentageToAsk: 9000,
        params: [],
      };

      const makeOrder: MakerOrder = {
        isOrderAsk: true,
        signer: erc721Owner.address,
        collection: erc721Token.address,
        price: 10,
        tokenId: 4,
        amount: 3,
        strategy: strategyStandardSaleForFixedPrice.address,
        currency: erc20Token.address,
        nonce: 2,
        startTime: 0,
        endTime: BigNumber.from(100000000000000),
        minPercentageToAsk: 9000,
        params: "0x",
      };

      const signedMakeOrder = await signMakeOrder(
        erc721Owner,
        depoExchange.address,
        makeOrder
      );

      const tx = await wertModule
        .connect(erc20Owner)
        .purchaseNFTWithETH(takeOrder, signedMakeOrder, {
          value: 10,
        });
      const receipt = await tx.wait();

      const afterBalance = await erc20Owner.getBalance();
      const ownerAfterBalance = await erc721Owner.getBalance();

      expect(
        await beforeBalance
          .sub(takeOrder.price)
          .sub(receipt.gasUsed.mul(receipt.effectiveGasPrice))
      ).to.be.equal(afterBalance);
      expect(ownerBeforeBalance.add(takeOrder.price)).to.be.equal(
        ownerAfterBalance
      );
      expect(await erc721Token.ownerOf(4)).to.be.equal(erc20Owner.address);
    });
    it("match should be confirmed for Arc721", async () => {
      const beforeBalance = await erc20Owner.getBalance();
      const ownerBeforeBalance = await erc721Owner.getBalance();
      const takeOrder = {
        isOrderAsk: false,
        taker: erc20Owner.address,
        price: 10,
        tokenId: 5,
        minPercentageToAsk: 9000,
        params: [],
      };

      const makeOrder: MakerOrder = {
        isOrderAsk: true,
        signer: erc721Owner.address,
        collection: arc721Token.address,
        price: 10,
        tokenId: 5,
        amount: 3,
        strategy: strategyStandardSaleForFixedPrice.address,
        currency: erc20Token.address,
        nonce: 3,
        startTime: 0,
        endTime: BigNumber.from(100000000000000),
        minPercentageToAsk: 9000,
        params: "0x",
      };

      const signedMakeOrder = await signMakeOrder(
        erc721Owner,
        depoExchange.address,
        makeOrder
      );

      const tx = await wertModule
        .connect(erc20Owner)
        .purchaseNFTWithETH(takeOrder, signedMakeOrder, {
          value: 10,
        });
      const receipt = await tx.wait();

      const afterBalance = await erc20Owner.getBalance();
      const ownerAfterBalance = await erc721Owner.getBalance();

      expect(
        await beforeBalance
          .sub(takeOrder.price)
          .sub(receipt.gasUsed.mul(receipt.effectiveGasPrice))
      ).to.be.equal(afterBalance);
      expect(ownerBeforeBalance.add(takeOrder.price)).to.be.equal(
        ownerAfterBalance
      );
      expect(await arc721Token.ownerOf(5)).to.be.equal(erc20Owner.address);
    });
  });
});
