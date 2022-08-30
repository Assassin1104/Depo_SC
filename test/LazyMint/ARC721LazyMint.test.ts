import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

import {
  Arc721,
  DepoCurrencyManager,
  DepoExchange,
  DepoExecutionManager,
  DepoRoyaltyFeeManager,
  DepoTransferSelectorNFT,
  MockERC20,
  RoyaltyFeeRegistry,
  StrategyAnyItemFromCollectionForFixedPrice,
  StrategyPrivateSale,
  StrategyStandardSaleForFixedPrice,
  TransferManagerERC1155,
  TransferManagerERC721,
} from "../../typechain";
import { signMakeOrder } from "../utils/meta_transaction";
import { deployContract } from "../utils/testHelper";

chai.use(solidity);

interface TakeOrder {
  isOrderAsk: boolean;
  taker: string;
  price: number;
  tokenId: number;
  minPercentageToAsk: number;
  params: Array<any>;
}

interface MakeOrder {
  isOrderAsk: boolean;
  signer: string;
  collection: string;
  price: number;
  tokenId: number;
  amount: number;
  strategy: string;
  currency: string;
  nonce: number;
  startTime: number;
  endTime: BigNumber;
  minPercentageToAsk: number;
  params: Array<any>;
}

describe("DepoExchange Test For Arc721", () => {
  let deployer: SignerWithAddress;
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

  let erc20Token: MockERC20;
  let arc721Token: Arc721;

  const protocolFeeRecipientAddress =
    "0x5924A28caAF1cc016617874a2f0C3710d881f3c1";

  before("Deploy contracts and preconfig", async () => {
    [deployer, erc20Owner, erc721Owner] = await ethers.getSigners();

    erc20Token = await deployContract(
      erc20Owner,
      "MockERC20",
      "MFT",
      "Mock ERC 20",
      1000
    );

    arc721Token = await deployContract(
      deployer,
      "Arc721",
      "https://images.arc.market/" // temporary base uri
    );

    //deploy DepoCurrencyManager
    currencyManager = await deployContract(deployer, "DepoCurrencyManager");
    await currencyManager.addCurrency(erc20Token.address);

    //deploy DepoExecutionManager
    executionManager = await deployContract(deployer, "DepoExecutionManager");

    //deploy StrategyStandardSaleForFixedPrice
    strategyStandardSaleForFixedPrice = await deployContract(
      deployer,
      "StrategyStandardSaleForFixedPrice",
      200
    );

    //deploy StrategyAnyItemFromCollectionForFixedPrice
    strategyAnyItemFromCollectionForFixedPrice = await deployContract(
      deployer,
      "StrategyAnyItemFromCollectionForFixedPrice",
      200
    );

    //deploy StrategyPrivateSale
    strategyPrivateSale = await deployContract(
      deployer,
      "StrategyPrivateSale",
      200
    );

    await executionManager.addStrategy(
      strategyStandardSaleForFixedPrice.address
    );
    await executionManager.addStrategy(
      strategyAnyItemFromCollectionForFixedPrice.address
    );
    await executionManager.addStrategy(strategyPrivateSale.address);

    //deploy RoyaltyFeeRegistry
    royaltyFeeRegistry = await deployContract(
      deployer,
      "RoyaltyFeeRegistry",
      9500
    );
    //deploy DepoRoyaltyFeeManager
    royaltyFeeManager = await deployContract(
      deployer,
      "DepoRoyaltyFeeManager",
      royaltyFeeRegistry.address
    );

    //deploy DepoExchange
    depoExchange = await deployContract(
      deployer,
      "DepoExchange",
      currencyManager.address,
      executionManager.address,
      royaltyFeeManager.address,
      erc20Token.address,
      protocolFeeRecipientAddress
    );

    transferManagerERC721 = await deployContract(
      deployer,
      "TransferManagerERC721",
      depoExchange.address
    );

    transferManagerERC1155 = await deployContract(
      deployer,
      "TransferManagerERC1155",
      depoExchange.address
    );

    //deploy DepoTransferSelectorNFT
    transferSelectorNFT = await deployContract(
      deployer,
      "DepoTransferSelectorNFT",
      transferManagerERC721.address,
      transferManagerERC1155.address
    );

    await depoExchange.updateTransferSelectorNFT(transferSelectorNFT.address);

    await erc20Token
      .connect(erc20Owner)
      .approve(
        depoExchange.address,
        await erc20Token.balanceOf(erc20Owner.address)
      );

    console.log("===== Allowing TransferManagerERC721 for Lazy mint =====");

    await arc721Token.addOperator(transferManagerERC721.address);
  });

  /**
   * @notice Maker is a seller and taker is a buyer
   */
  describe("matchAskWithTakerBid", async () => {
    let takeOrder: TakeOrder, makeOrder: MakeOrder;
    before(async () => {
      takeOrder = {
        isOrderAsk: false,
        taker: erc20Owner.address,
        price: 10,
        tokenId: 1,
        minPercentageToAsk: 9000,
        params: [],
      };

      makeOrder = {
        isOrderAsk: true,
        signer: erc721Owner.address,
        collection: arc721Token.address,
        price: 10,
        tokenId: 1,
        amount: 1, // should be 1 for ERC721
        strategy: strategyStandardSaleForFixedPrice.address,
        currency: erc20Token.address,
        nonce: 1,
        startTime: 0,
        endTime: BigNumber.from(100000000000000),
        minPercentageToAsk: 9000,
        params: [],
      };
    });

    it("match should be confirmed", async () => {
      const beforBalance = await erc20Token.balanceOf(erc20Owner.address);

      const signedMakeOrder = await signMakeOrder(
        erc721Owner,
        depoExchange.address,
        makeOrder
      );

      await expect(arc721Token.ownerOf(1)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      await depoExchange
        .connect(erc20Owner)
        .matchAskWithTakerBid(takeOrder, signedMakeOrder);

      const afterBalance = await erc20Token.balanceOf(erc20Owner.address);
      expect(beforBalance.sub(takeOrder.price)).to.be.equal(afterBalance);
      expect(await arc721Token.ownerOf(1)).to.be.equal(erc20Owner.address);
    });

    it("should get the correct uri", async () => {
      expect(await arc721Token.tokenURI(1)).to.be.eq(
        "https://images.arc.market/1"
      );
    });
  });

  /**
   * @notice Maker is a buyer and taker is a seller
   */
  describe("matchBidWithTakerAsk", async () => {
    let takeOrder: TakeOrder, makeOrder: MakeOrder;
    before(async () => {
      takeOrder = {
        isOrderAsk: true,
        taker: erc721Owner.address,
        price: 10,
        tokenId: 2,
        minPercentageToAsk: 9000,
        params: [],
      };

      makeOrder = {
        isOrderAsk: false,
        signer: erc20Owner.address,
        collection: arc721Token.address,
        price: 10,
        tokenId: 2,
        amount: 1, // should be 1 for ERC721
        strategy: strategyStandardSaleForFixedPrice.address,
        currency: erc20Token.address,
        nonce: 2,
        startTime: 0,
        endTime: BigNumber.from(100000000000000),
        minPercentageToAsk: 9000,
        params: [],
      };
    });

    it("match should be confirmed", async () => {
      const beforBalance = await erc20Token.balanceOf(erc20Owner.address);

      const signedMakeOrder = await signMakeOrder(
        erc20Owner,
        depoExchange.address,
        makeOrder
      );

      await expect(arc721Token.ownerOf(2)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );

      await depoExchange
        .connect(erc721Owner)
        .matchBidWithTakerAsk(takeOrder, signedMakeOrder);

      const afterBalance = await erc20Token.balanceOf(erc20Owner.address);
      expect(beforBalance.sub(takeOrder.price)).to.be.equal(afterBalance);
      expect(await arc721Token.ownerOf(2)).to.be.equal(erc20Owner.address);
    });

    it("should get the correct uri", async () => {
      expect(await arc721Token.tokenURI(2)).to.be.eq(
        "https://images.arc.market/2"
      );
    });
  });
});
