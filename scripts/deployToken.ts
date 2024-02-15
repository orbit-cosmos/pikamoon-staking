
import { ethers } from "hardhat";
import {tokenArgs} from "../args/Token";
async function main() {
  const [owner] = await ethers.getSigners();
  const ICOToken = await ethers.getContractFactory("ICOToken");
  const token = await ICOToken.deploy(tokenArgs[0], tokenArgs[1], tokenArgs[2],tokenArgs[3],tokenArgs[4]);

  console.log("ICOToken", token.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
