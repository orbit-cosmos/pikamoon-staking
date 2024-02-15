import { ethers } from "hardhat";
import {stakingArgs} from "../args/Staking";
async function main() {
  const [owner] = await ethers.getSigners();

  const PikaStaking = await ethers.getContractFactory("PikaStaking");

  const staking = await PikaStaking.deploy(
    stakingArgs[0],

  );

  console.log("staking", staking.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
