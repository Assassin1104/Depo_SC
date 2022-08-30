async function main() {
  const Arc721 = await ethers.getContractFactory("Arc721");
  const nft = await Arc721.deploy();
  await nft.deployed();
  console.log("Arc721 deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
