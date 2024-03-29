import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers,upgrades } from "hardhat";
import { PikaMoon, PikaStaking } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

const toGWei = (value: number) => ethers.parseUnits(value.toString(),9);
// const fromWei = (value: number) => ethers.formatEther(value);
// const now = () => Math.floor(Date.now() / 1000);
describe("Pika Staking contract testcases", function () {
  async function deployICOFixture() {
    const [owner, stakingReward,account1, account2,] = await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");
    
    const token = await upgrades.deployProxy(pikamoon,
      [
        "PIKAMoon",
        "PIKA",
        owner.address,
        owner.address
      ],
      { initializer: "initialize"}
      
      );
      
      const PoolFactory = await ethers.getContractFactory("PoolFactory");
      const poolFactory = await PoolFactory.deploy();


      const PikaStaking = await ethers.getContractFactory("DirectStaking");
      const staking = await PikaStaking.deploy(
        token.target,
        token.target,
        poolFactory.target,
        200,
        stakingReward.address
        );
    // grant admin role to staking contract
    await token
      .connect(owner)
      .grantRole(
        "0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e", // role
        staking.target
      );


      await token.mint(stakingReward.address, toGWei(5_000_000_000));
      await token.connect(stakingReward).approve(staking.target, toGWei(5_000_000_000));
      await token.mint(account2.address, toGWei(50));
      await token.mint(account1.address, toGWei(50));
      await token.excludeFromTax(staking.target,true);

    return { token, staking, owner, account1, account2 };
  }

  describe("fn Stake()", async function () {
    let token: PikaMoon,
      staking: PikaStaking,
      owner,
      account1: HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployICOFixture);
      token = fixture?.token;
      staking = fixture?.staking;
      owner = fixture?.owner;
      account1 = fixture?.account1;
    });

    it("should not allow to stake if value is zero", async () => {
      let stakingAmount = toGWei(0);
      const ONE_MONTH_IN_SECS =  30 * 24 * 60 * 60 ;
      await expect(
        staking.stake(stakingAmount, ONE_MONTH_IN_SECS)
      ).to.be.revertedWithCustomError(staking, "ZeroAmount");
    });

    it("should not allow to stake if lock duration is less then minimum lock duration", async () => {
      let stakingAmount = toGWei(50);
      const ONE_DAY_IN_SECS =  24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_DAY_IN_SECS)
      ).to.be.revertedWithCustomError(staking, "InvalidLockDuration");
    });
    it("should not allow to stake if lock duration is greater then maximum lock duration", async () => {
      let stakingAmount = toGWei(50);
      const ONE_DAY_IN_SECS = 366 * 24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_DAY_IN_SECS)
      ).to.be.revertedWithCustomError(staking, "InvalidLockDuration");
    });

    it("should not allow to stake if not allowed staking contract", async () => {
      let stakingAmount = toGWei(50);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60 ;
      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS)
      ).to.be.revertedWithCustomError(token, "ERC20InsufficientAllowance");
    });

 

    it("should not allow to stake if contract is paused", async () => {
      await staking.pause(true);
      let stakingAmount = toGWei(50);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60 ;
      await expect(
        staking.stake(stakingAmount, ONE_MONTH_IN_SECS)
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    });

    it("should allow to stake", async () => {
      let stakingAmount = toGWei(50);
      await token.connect(account1).approve(staking.target, stakingAmount);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60 ;
      expect(await token.balanceOf(account1.address)).to.be.equal(
        stakingAmount
      );
      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS)
      ).to.emit(staking, "LogStake");
      expect(await token.balanceOf(account1.address)).to.be.equal("0");
    });
 
    it("should allow claim if contract is paused", async () => {
      await staking.pause(true);
      await expect(staking.connect(account1).claimRewards()
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    })

    it("should allow claim", async () => {

      await expect(staking.connect(account1).claimRewards()).to.emit(
        staking,
        "LogClaimRewards"
      );
    })



    it("should allow unstake if contract is paused", async () => {
      await staking.pause(true);
      await expect(staking.connect(account1).unstake(0)
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    })
    it("should allow unstake ", async () => {
      await time.increase( 30 * 24 * 60 * 60);
      await expect(
        staking.connect(account1).unstake(0)
      ).to.emit(staking, "LogUnstake");

    })
  });

});
