const {ethers, upgrades} = require("hardhat");

async function main() {
  const StableCoinStaking_version1 = await ethers.getContractFactory("StableCoinStaking_version1");
  const stableCoinStaking_version1 = await upgrades.deployProxy(StableCoinStaking_version1, ["0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7"], ["0xbc6c4102C8A18Cc11cfCDb6C1b5fb3b739B336dd"],                                                       
    {
      initializer: "initialize",
      kind: "transparent",
    }
  );
  await stableCoinStaking_version1.deployed();

  console.log(`stableCoinStaking_version1 deployed to ${stableCoinStaking_version1.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

