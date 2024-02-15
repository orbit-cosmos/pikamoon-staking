const hre = require("hardhat");
const StakingARG = require("../args/Staking");
async function main() {
  const [owner] = await ethers.getSigners();

  const PikaStaking = await ethers.getContractFactory("PikaStaking");

  const staking = await PikaStaking.deploy(
    StakingARG[0],

  );
  await staking.deployed();


  console.log("staking", staking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
