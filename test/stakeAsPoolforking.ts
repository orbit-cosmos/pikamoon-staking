import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, DirectStaking, PoolController } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";
import { ZeroAddress } from "ethers";
import { lstat } from "fs";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);
const toWei = (value: number) => ethers.parseEther(value.toString());
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
  async function deployFixture() {
    const [verifierAddress] = await ethers.getSigners();
    const owner = await ethers.getImpersonatedSigner("0x574e11B602D05187cdA67d69fd6dd4E5c9a42f63");
    //const verifierAddress = await ethers.getImpersonatedSigner("0x082d14dc6433f51dbd9d8a16a33324abb6a087d3");
    const account1 = await ethers.getImpersonatedSigner("0x03dF740E2215F3495218F9c15C6774ced369252c");
    const wale = await ethers.getImpersonatedSigner("0x00000000219ab540356cBB839Cbe05303d7705Fa"); 
    await wale.sendTransaction({
      to: owner.address,
      value: ethers.parseEther("11.0"), 
    });
    await wale.sendTransaction({
      to: account1.address,
      value: ethers.parseEther("11.0"), 
    });
    const pikamoon = await ethers.getContractFactory("PikaMoon");
    const ERC20 =  await ethers.getContractFactory("Token")
   
    const token = await pikamoon.attach("0xd1e64bcc904cfdc19d0faba155a9edc69b4bcdae");
 
    const lptoken = await ERC20.attach("0x43a68a9f1f234e639b142f0aba946b7add26418d")
    const PoolController = await ethers.getContractFactory("PoolController");
    const poolController = await PoolController.attach("0x1cA441f054CCD878A3f9Dba4c35092fD1e07D17f");
    const PikaStaking = await ethers.getContractFactory("PikaStakingPool");
    const staking = await PikaStaking.attach("0xF965671DeC4C8f902083e8E0845cf86aac44FD80");
    const lpstaking = await PikaStaking.attach("0xFCf12ADF9Dc9967701596A12D1c7F5E447e34736");

    const stakingNewImpl = await ethers.deployContract("PikaStakingPool", [])
    
    //lp staking upgrade to new implementation 
    await owner.sendTransaction({
        to: lpstaking.target,
        data:`0x4f1ef286000000000000000000000000${stakingNewImpl.target.toString().slice(2)}00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000`,
      });
      //Direct staking upgrade to new implementation 
    await owner.sendTransaction({
        to: staking.target,
        data:`0x4f1ef286000000000000000000000000${stakingNewImpl.target.toString().slice(2)}00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000`,
      });
      const poolControllerNewImpl = await ethers.deployContract("PoolController",[])
       //pool controller upgrade to new implementation 
    await owner.sendTransaction({
        to: poolController.target,
        data:`0x4f1ef286000000000000000000000000${poolControllerNewImpl.target.toString().slice(2)}00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000`,
      });
      

    console.log('2')
  //  const lpstaking = await PikaStaking.attach(lp);
    await lpstaking.connect(owner).setVerifierAddress(verifierAddress.address);
    await staking.connect(owner).setVerifierAddress(verifierAddress.address);
    await poolController.connect(owner).addPool(staking.target,token.target)
    console.log("here2")
   
    return { token,lptoken, staking,lpstaking, owner, account1, poolController,verifierAddress };
  }

  describe("test cases", async function () {
    let token: PikaMoon,
      lptoken: PikaMoon,
      staking: DirectStaking,
      lpstaking: DirectStaking,
      owner: HardhatEthersSigner,
      poolController: PoolController,
      verifierAddress: HardhatEthersSigner,
      account1: HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployFixture);
      token = fixture?.token;
      lptoken = fixture?.lptoken;
      staking = fixture?.staking;
      lpstaking = fixture?.lpstaking;
      owner = fixture?.owner;
      account1 = fixture?.account1;
      poolController = fixture?.poolController;
      verifierAddress = fixture?.verifierAddress;

  
    });
    it("should allow to stake in lp", async () => {
        let stakingAmount = await lptoken.balanceOf(account1.address)
        console.log("stakingAmount",stakingAmount)
        await lptoken.connect(account1).approve(lpstaking.target, stakingAmount);
        const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        expect(await lptoken.balanceOf(account1.address)).to.be.equal(
          stakingAmount,
        );
        console.log("here2")
        expect(await lpstaking.getStakesLength(account1.address)).to.be.equal(0);
        console.log("here3")
        await expect(
          lpstaking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
        ).to.emit(lpstaking, "LogStake");
        console.log("here4",(await lpstaking.getStake(account1.address, 0)))
        expect((await lpstaking.getStake(account1.address, 0))[0]).to.be.eq(
          stakingAmount,
        );
        console.log("here5")
        expect(await lpstaking.getStakesLength(account1.address)).to.be.equal(1);
        expect(await lptoken.balanceOf(account1.address)).to.be.equal("0");
        expect(await lpstaking.balanceOf(account1.address)).to.be.equal(
          stakingAmount,
        );
      });
    it("should allow claim with restake", async () => {
       
        let _time = new Date().getTime();
        const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const message = encodeAndHash(
          account1.address,
          0,
          true,
          _time,
        );
         const signature = await verifierAddress.signMessage(ethers.toBeArray(message));
    
        await time.increase(30 * 24 * 60 * 60);
       
        console.log("bal before",await token.balanceOf(staking.target))
       await expect(
          await lpstaking
            .connect(account1)
            .claimRewards(0, true, signature, _time),
       )
      .to.emit(staking, "LogStake");
       
        expect(await lpstaking.getStakesLength(account1.address)).to.be.equal(1);
        expect(await staking.getStakesLength(account1.address)).to.be.equal(1);
       console.log("bal after",await token.balanceOf(staking.target))
      });

      it.skip("should restake after claiming with restake", async () => {
        let _time = new Date().getTime();
        const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const message = encodeAndHash(
          account1.address,
          500,
          true,
          _time,
        );
        const signature = await verifierAddress.signMessage(ethers.toBeArray(message));
        await time.increase(30 * 24 * 60 * 60);
        console.log("bal before",await staking.balanceOf(account1.address))
        await expect(
          staking
            .connect(account1)
            .claimRewards(500, true, signature, _time),
        ).to.emit(staking, "LogStake");
        expect(await lpstaking.getStakesLength(account1.address)).to.be.equal(1);
        expect(await staking.getStakesLength(account1.address)).to.be.equal(2);
       console.log("bal after",await staking.balanceOf(account1.address))

      });
      it.skip("should allow unstake ", async () => {
        await time.increase(30 * 24 * 60 * 60);
        let stakeBal = await staking.balanceOf(account1.address);
        console.log("stakeBal",stakeBal)
        await expect(staking.connect(account1).unstake(0)).to.emit(
          staking,
          "LogUnstake",
        );
        stakeBal = await staking.balanceOf(account1.address);
        console.log("stakeBal after",stakeBal)
        await expect(staking.connect(account1).unstake(0)).to.be.revertedWithCustomError(
          staking,
          "AlreadyUnstaked",
        );
      });
  
    
     });
});
