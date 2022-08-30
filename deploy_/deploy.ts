import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";

const depoExchange: DeployFunction = async (hre) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const [deployer] = await ethers.getSigners();

  const addr = deployer.address;

  console.log("Arc721 contracts with the account:", addr);
  //deploy Arc721
  const arc721 = await deploy("Arc721", {
    from: addr,
    args: [""],
    log: true,
  });

  console.log("Arc1155 contracts with the account:", addr);
  //deploy DepoCurrencyManager
  const arc1155 = await deploy("Arc1155", {
    from: addr,
    args: [""],
    log: true,
  });
  console.log("Deploying contracts with the account:", addr);

  //deploy DepoCurrencyManager
  const currencyManager = await deploy("DepoCurrencyManager", {
    from: addr,
    args: [],
    log: true,
  });

  console.log(`DepoCurrencyManager deployed to:`, currencyManager.address);

  //deploy DepoExecutionManager
  const executionManager = await deploy("DepoExecutionManager", {
    from: addr,
    args: [],
    log: true,
  });
  console.log(`DepoExecutionManager deployed to:`, executionManager.address);

  //deploy RoyaltyFeeRegistry
  const royaltyFeeRegistry = await deploy("RoyaltyFeeRegistry", {
    from: addr,
    args: [9000],
    log: true,
  });
  console.log(`RoyaltyFeeRegistry deployed to:`, royaltyFeeRegistry.address);

  //deploy DepoRoyaltyFeeManager
  const royaltyFeeManager = await deploy("DepoRoyaltyFeeManager", {
    from: addr,
    args: [royaltyFeeRegistry.address],
    log: true,
  });
  console.log(`DepoRoyaltyFeeManager deployed to:`, royaltyFeeManager.address);

  //0xc778417e063141139fce010982780140aa0cd5ab WETH
  //deploy DepoExchange
  const depoExchange = await deploy("DepoExchange", {
    from: addr,
    args: [
      currencyManager.address,
      executionManager.address,
      royaltyFeeManager.address,
      "0xc778417e063141139fce010982780140aa0cd5ab",
      addr,
    ],
    log: true,
  });
  console.log(`DepoExchange deployed to:`, depoExchange.address);

  //deploy StrategyAnyItemFromCollectionForFixedPrice
  const strategyAnyItemFromCollectionForFixedPrice = await deploy(
    "StrategyAnyItemFromCollectionForFixedPrice",
    {
      from: addr,
      args: [200],
      log: true,
    }
  );
  console.log(
    `StrategyAnyItemFromCollectionForFixedPrice deployed to:`,
    strategyAnyItemFromCollectionForFixedPrice.address
  );

  //deploy StrategyPrivateSale
  const strategyPrivateSale = await deploy("StrategyPrivateSale", {
    from: addr,
    args: [200],
    log: true,
  });
  console.log(`StrategyPrivateSale deployed to:`, strategyPrivateSale.address);

  //deploy StrategyStandardSaleForFixedPrice
  const strategyStandardSaleForFixedPrice = await deploy(
    "StrategyStandardSaleForFixedPrice",
    {
      from: addr,
      args: [200],
      log: true,
    }
  );
  console.log(
    `StrategyStandardSaleForFixedPrice deployed to:`,
    strategyStandardSaleForFixedPrice.address
  );

  //deploy TransferManagerERC721
  const transferManagerERC721 = await deploy("TransferManagerERC721", {
    from: addr,
    args: [depoExchange.address],
    log: true,
  });
  console.log(
    `TransferManagerERC721 deployed to:`,
    transferManagerERC721.address
  );

  //deploy TransferManagerERC1155
  const transferManagerERC1155 = await deploy("TransferManagerERC1155", {
    from: addr,
    args: [depoExchange.address],
    log: true,
  });
  console.log(
    `TransferManagerERC1155 deployed to:`,
    transferManagerERC1155.address
  );

  //deploy DepoTransferSelectorNFT
  const transferSelectorNFT = await deploy("DepoTransferSelectorNFT", {
    from: addr,
    args: [transferManagerERC721.address, transferManagerERC1155.address],
    log: true,
  });
  console.log(
    `DepoTransferSelectorNFT deployed to:`,
    transferSelectorNFT.address
  );
};

export default depoExchange;
depoExchange.tags = ["DepoExchange"];
