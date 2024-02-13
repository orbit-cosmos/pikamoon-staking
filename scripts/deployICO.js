const hre = require("hardhat");
const ICOARG = require("../args/ICO");
async function main() {
  console.log(ICOARG);
  const [owner] = await ethers.getSigners();
  const ICOToken = await ethers.getContractFactory("ICOToken");
  const token = ICOToken.attach(ICOARG[5]);
  const ICO = await ethers.getContractFactory("ICO");

  const ico = await ICO.deploy(
    ICOARG[0],
    ICOARG[1],
    ICOARG[2], // token
  );
  await ico.deployed();

  await token.connect(owner).mint(ico.address, ethers.utils.parseEther("1000000", "wei"));
  console.log("ICO", ico.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
