/**
 * @title testHelper
 * @author jasondepo
 * @dev Helper functions for unit tests
 *
 */

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";

/**
 * @dev Deploy a contract with specified arguments, including optional arguments.
 * @param name Name of the contract.
 * @param arg List of arguments to be passed into the contract constructor.
 * @returns Intsance of a contract.
 */
const deployContract = async (
  signer: SignerWithAddress,
  name: string,
  ...arg: any[]
): Promise<any> => {
  const contractFactory = await ethers.getContractFactory(name);
  const contract = await contractFactory.connect(signer).deploy(...arg);
  await contract.deployed();
  console.log(`${name} is deployed at ${contract.address}`);
  return contract;
};

/**
 * @dev Get the contract instance from the address and contract name.
 * @param name Contract name.
 * @param address Contract address.
 * @returns Instance of the contract specified by `name` and `address`.
 */
const getContractAt = async (name: string, address: string): Promise<any> => {
  return await ethers.getContractAt(name, address);
};

export { deployContract, getContractAt };
