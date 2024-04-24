import { ethers,upgrades } from "hardhat";
async function main() {
  const [owner] = await ethers.getSigners();
  const pikamoon = await ethers.getContractFactory("PikaMoon");

  const token = await upgrades.deployProxy(
    pikamoon,
    ["PIKAMoon", "PIKA", owner.address, owner.address],
    { initializer: "initialize" },
  );
  const PoolController = await ethers.getContractFactory("PoolController");
  const poolController = await upgrades.deployProxy(PoolController, [], {
    initializer: "initialize",
  });

  const PikaStaking = await ethers.getContractFactory("PikaStakingPool");
  const staking = await upgrades.deployProxy(
    PikaStaking,
    [token.target, token.target, poolController.target, 200],
    { initializer: "initialize" },
  );


  console.log(`staking address: ${staking.target}, poolController address: ${poolController.target}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
