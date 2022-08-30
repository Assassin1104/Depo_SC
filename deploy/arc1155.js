async function main() {
  const Arc1155 = await ethers.getContractFactory("Arc1155");
  const nft = await Arc1155.deploy();
  await nft.deployed();
  console.log("Arc1155 deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
