import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, DirectStaking, PoolController } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";
import { Transaction, ZeroAddress } from "ethers";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);

function encodeAndHash(
  address: Address | string,
  amount: bigint | number,
  restake: boolean,
  nonce: bigint | number,
) {
  return ethers.solidityPackedKeccak256(
    ["address", "uint256", "bool", "uint256"],
    [address, amount, restake, nonce],
  );
}
describe("Pika Staking", function () {


  describe("test cases", async function () {
   
    it("should reset state",async()=>{
      const PikaStaking = await ethers.getContractFactory("PikaStakingPool");
      let staking = PikaStaking.attach("0xFCf12ADF9Dc9967701596A12D1c7F5E447e34736")
      
      

      const wale = await ethers.getImpersonatedSigner("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
      
      const user1 = await ethers.getImpersonatedSigner("0xf89Cac39cB5135f5907f4CeA4E84898841C4768D");
      const user2 = await ethers.getImpersonatedSigner("0x37017A26eF9D51C4e38bfB712F7748E531e48c57");



     

      await wale.sendTransaction({
        to:user1.address,
        value:1000000000000000000n
    })

    await wale.sendTransaction({
      to:user2.address,
      value:1000000000000000000n
  })
      
      
      await staking.connect(user1).unstake(0);
      await staking.connect(user2).unstake(1);

        // console.log(await staking.getStake("0xc37cDFd51EA3001F09AF0A784FEeC5518Fd6df4A",0))
        // console.log(await staking.getStake("0xc37cDFd51EA3001F09AF0A784FEeC5518Fd6df4A",1))
        console.log((await staking.users("0xc37cDFd51EA3001F09AF0A784FEeC5518Fd6df4A")))

        console.log("user1",(await staking.users("0xf89Cac39cB5135f5907f4CeA4E84898841C4768D")))
        console.log("user2",(await staking.users("0x37017A26eF9D51C4e38bfB712F7748E531e48c57")))
        // console.log(await staking.getStake("0xc37cDFd51EA3001F09AF0A784FEeC5518Fd6df4A",2))
        
        
        console.log("rewardsPerWeight",await staking.rewardsPerWeight())
        console.log("globalStakeWeight",await staking.globalStakeWeight())
        // console.log(await staking.totalTokenStaked())
    

    })
  })
})