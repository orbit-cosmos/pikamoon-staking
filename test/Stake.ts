import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { PikaMoon,PikaStaking } from "../typechain-types";
import { Addressable } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const toWei = (value:number) => ethers.parseEther(value.toString());
const fromWei = (value:number) => ethers.formatEther(value);
const now = () => Math.floor(Date.now() / 1000); 
describe("Pika Staking contract testcases", function () {
  async function deployICOFixture() {
    const [owner, otherAccount, account2] = await ethers.getSigners();
    const ICOToken = await ethers.getContractFactory("PikaMoon");
    const PikaStaking = await ethers.getContractFactory("PikaStaking");

    const token = await ICOToken.deploy("PIKAMoon", "PIKA", toWei(5000000000),account2.address,account2.address);

    const staking = await PikaStaking.deploy(
      token.target,
    );
    console.log("owner",owner.address)
      await token.connect(owner).grantRole("0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e",staking.target)

    return { token, staking, owner, otherAccount, account2 };
  }

  describe("fn Stake()", async function () {
    let token:PikaMoon, staking:PikaStaking, owner, otherAccount:HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployICOFixture);
      token = fixture?.token;
      staking = fixture?.staking;
      owner = fixture?.owner;
      otherAccount = fixture?.otherAccount;
    });


    it("should not allow to stake if value is zero",async()=>{
        let stakingAmount = toWei(0); 
        const ONE_DAY_IN_SECS =  1 * 60 * 60;
        await expect(staking.stake(stakingAmount,ONE_DAY_IN_SECS))
        .to.be.revertedWithCustomError(staking,"ZeroAmount")
        
    })


    it("should not allow to stake if lock duration is less then minimum lock duration",async()=>{
        let stakingAmount = toWei(5000); 
        const ONE_DAY_IN_SECS =  1 * 60 ;
        await expect(staking.stake(stakingAmount,ONE_DAY_IN_SECS))
        .to.be.revertedWithCustomError(staking,"InvalidLockDuration")
        
    })
    it("should not allow to stake if lock duration is greater then maximum lock duration",async()=>{
        let stakingAmount = toWei(5000); 
        const ONE_DAY_IN_SECS =  1 * 60 * 60 * 60
        await expect(staking.stake(stakingAmount,ONE_DAY_IN_SECS))
        .to.be.revertedWithCustomError(staking,"InvalidLockDuration")
        
    })

    it("should not allow to stake if not allowed staking contract",async()=>{
        let stakingAmount = toWei(5000); 
        const ONE_YEAR  =  1 * 60 * 60
        await expect(staking.connect(otherAccount).stake(stakingAmount,ONE_YEAR))
        .to.be.revertedWithCustomError(token,"ERC20InsufficientAllowance")
        
        
    })
    
    it("should allow to stake",async()=>{
      await token.mint(otherAccount.address, toWei(5000))
        let stakingAmount = toWei(5000); 
        await token.connect(otherAccount).approve(staking.target,stakingAmount)
        const ONE_YEAR  =  1 * 60 * 60
        expect(await token.balanceOf(otherAccount.address)).to.be.equal(stakingAmount)
        await expect(staking.connect(otherAccount).stake(stakingAmount,ONE_YEAR))
        .to.emit(staking,"LogStake")
        expect(await token.balanceOf(otherAccount.address)).to.be.equal("0")
    })
    
    it("should not allow to stake if contract is paused",async()=>{
      await staking.pause(true);
      let stakingAmount = toWei(0); 
      const ONE_DAY_IN_SECS =  1 * 60 * 60;
      await expect(staking.stake(stakingAmount,ONE_DAY_IN_SECS))
      .to.be.revertedWithCustomError(staking,"ContractIsPaused")
      
  })
})


describe("fn claimYieldRewards()", async function () {
  let token:PikaMoon, staking:PikaStaking, owner, otherAccount:HardhatEthersSigner;

  before(async () => {
    let fixture = await loadFixture(deployICOFixture);
    token = fixture.token;
    staking = fixture.staking;
    owner = fixture.owner;
    otherAccount = fixture.otherAccount;
  });

  it("should allow claim",async()=>{
    await token.mint(otherAccount.address, toWei(5000))
    let stakingAmount = toWei(5000); 
    await token.connect(otherAccount).approve(staking.target,stakingAmount)
    const ONE_YEAR  =  1 * 60 * 60
    
    expect(await token.balanceOf(otherAccount.address)).to.be.equal(stakingAmount)
    
    await expect(staking.connect(otherAccount).stake(stakingAmount,ONE_YEAR))
    .to.emit(staking,"LogStake")

    expect(await token.balanceOf(otherAccount.address)).to.be.equal("0")
    
    await expect(staking.connect(otherAccount).claimYieldRewards())
    .to.emit(staking,"LogClaimYieldRewards")
 
    
})
})
})