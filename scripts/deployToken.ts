const hre = require("hardhat");
const Token = require("../args/Token");
async function main() {
  const [owner] = await ethers.getSigners();
  const ICOToken = await ethers.getContractFactory("ICOToken");
  const token = await ICOToken.deploy(Token[0], Token[1], Token[2],Token[3],Token[4]);
  await token.deployed();

  console.log("ICOToken", token.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
