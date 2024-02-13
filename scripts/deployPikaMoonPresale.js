const hre = require("hardhat");
const ICOARG = require("../args/ICO");
async function main() {

  const [owner] = await ethers.getSigners();

  const ICO = await ethers.getContractFactory("TestPikamoonPresale");

  const ico = await ICO.attach("0x11f32C49506F4DCF6683c0008Ec91ef2D59c82eB")
  const toWei = value => ethers.utils.parseEther(value.toString());
  let investmentEthAmount = toWei("0.000000177756");
  await ico.buyTokensEth({ value: investmentEthAmount })
//   await ico.connect(owner).addPhases([
//     {
//       roundId: 1,
//       maxTokens: toWei("5000000000"),
//       tokenPriceInUsd: 200, // 0.0002 usdt
//       claimStart: Math.floor(Date.now() / 1000),
//     },
//     {
//       roundId: 2,
//       maxTokens: toWei("5000000000"),
//       tokenPriceInUsd: 400, // 0.0004 usdt
//       claimStart: Math.floor(Date.now() / 1000) + 6000000,
//     },
// ]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
