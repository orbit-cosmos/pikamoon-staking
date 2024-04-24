import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, DirectStaking, PoolController } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";
import { ZeroAddress } from "ethers";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);

function encodeAndHash(
  address: Address | string,
  amount: bigint | number,
  restake: boolean,
  duration: bigint | number,
  nonce: bigint | number,
) {
  return ethers.solidityPackedKeccak256(
    ["address", "uint256", "bool", "uint256", "uint256"],
    [address, amount, restake, duration, nonce],
  );
}
describe("Pika Staking", function () {
  async function deployFixture() {
    const [owner, _, account1, account2] =
      await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");

    const token = await upgrades.deployProxy(
      pikamoon,
      ["PIKAMoon", "PIKA", owner.address, owner.address],
      { initializer: "initialize" },
    );

    const PoolController = await ethers.getContractFactory("PoolController");
    const poolController = await upgrades.deployProxy(PoolController, [], {
      initializer: "initialize",
    });

    const PikaStaking = await ethers.getContractFactory("PikaStakingPool");

    await expect(upgrades.deployProxy(
      PikaStaking,
      [ZeroAddress, token.target, poolController.target, 200],
      { initializer: "initialize" },
    )).to.be.reverted


    await expect(upgrades.deployProxy(
      PikaStaking,
      [ token.target,ZeroAddress, poolController.target, 200],
      { initializer: "initialize" },
    )).to.be.reverted
    await expect(upgrades.deployProxy(
      PikaStaking,
      [ token.target,token.target, ZeroAddress, 200],
      { initializer: "initialize" },
    )).to.be.reverted

  
    const staking = await upgrades.deployProxy(
      PikaStaking,
      [token.target, token.target, poolController.target, 200],
      { initializer: "initialize" },
    );

    await poolController.registerPool(staking.target);
    await token.mint(poolController.target, toGWei(5_000_000_000));
    await token.mint(account2.address, toGWei(50));
    await token.mint(account1.address, toGWei(50));
    await token.excludeFromTax(staking.target, true);

    return { token, staking, owner, account1, account2,poolController };
  }

  describe("test cases", async function () {
    let token: PikaMoon,
      staking: DirectStaking,
      owner: HardhatEthersSigner,
      poolController: PoolController,
      account1: HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployFixture);
      token = fixture?.token;
      staking = fixture?.staking;
      owner = fixture?.owner;
      account1 = fixture?.account1; 
      poolController = fixture?.poolController; 
    });

    // ************* stake **************

    it("should not allow to stake if value is zero", async () => {
      let stakingAmount = toGWei(0);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.be.revertedWithCustomError(staking, "ZeroAmount");
    });

    it("should not allow to stake if lock duration is less then minimum lock duration", async () => {
      let stakingAmount = toGWei(50);
      const ONE_DAY_IN_SECS = 24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_DAY_IN_SECS),
      ).to.be.revertedWithCustomError(staking, "InvalidLockDuration");
    });
    it("should not allow to stake if lock duration is greater then maximum lock duration", async () => {
      let stakingAmount = toGWei(50);
      const ONE_DAY_IN_SECS = 366 * 24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_DAY_IN_SECS),
      ).to.be.revertedWithCustomError(staking, "InvalidLockDuration");
    });

    it("should not allow to stake if not allowed staking contract", async () => {
      let stakingAmount = toGWei(50);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.be.revertedWithCustomError(token, "ERC20InsufficientAllowance");
    });

    it("should not allow to stake if contract is paused", async () => {
      await staking.pause(true);
      let stakingAmount = toGWei(50);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      await expect(
        staking.stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    });

    it("should allow to stake", async () => {
      let stakingAmount = toGWei(50);
      await token.connect(account1).approve(staking.target, stakingAmount);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      expect(await token.balanceOf(account1.address)).to.be.equal(
        stakingAmount,
      );
      expect(await staking.getStakesLength(account1.address)).to.be.equal(0)
      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
        ).to.emit(staking, "LogStake");
        expect((await staking.getStake(account1.address,0))[0]).to.be.eq(stakingAmount)
        expect(await staking.getStakesLength(account1.address)).to.be.equal(1)
      expect(await token.balanceOf(account1.address)).to.be.equal("0");
      expect(await staking.balanceOf(account1.address)).to.be.equal(stakingAmount);
    });

    // ************* claim **************

    it("should allow claim if contract is paused", async () => {
      await staking.pause(true);
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        true,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(500, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    });
    it("should not allow claim if tampered", async () => {
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        true,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(501, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.be.revertedWithCustomError(staking, "WrongHash");
    });

    it("should not allow claim if claim % is wrong", async () => {
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        true,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(10001, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.be.reverted;
    });
    it("should allow claim with restake", async () => {
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        true,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(500, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.emit(staking, "LogClaimRewards");
      expect(await staking.getStakesLength(account1.address)).to.be.equal(2)
    });


    it("should allow claim with out restake", async () => {
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        false,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(500, false, ONE_MONTH_IN_SECS, signature, time),
      ).to.emit(staking, "LogClaimRewards");
      expect(await staking.getStakesLength(account1.address)).to.be.equal(2)
    });

    it("should revert because of signature replay protection on claim", async () => {
      let time = new Date().getTime();
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
      const message = encodeAndHash(
        account1.address,
        500,
        true,
        ONE_MONTH_IN_SECS,
        time,
      );
      const signature = await owner.signMessage(ethers.toBeArray(message));
      await expect(
        staking
          .connect(account1)
          .claimRewards(500, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.emit(staking, "LogClaimRewards");
      expect(await staking.getStakesLength(account1.address)).to.be.equal(3)
      await expect(
        staking
          .connect(account1)
          .claimRewards(500, true, ONE_MONTH_IN_SECS, signature, time),
      ).to.be.reverted;
    });

    // ************* unstake **************
  
    it("should not allow unstake if contract is paused", async () => {
      await staking.pause(true);
      await expect(
        staking.connect(account1).unstake(0),
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    });
    it("should allow unstake ", async () => {
      await time.increase(30 * 24 * 60 * 60);
      await expect(staking.connect(account1).unstake(0)).to.emit(
        staking,
        "LogUnstake",
      );
    });

    it("should allow early unstake ", async () => {
      let stakingAmount = toGWei(50);
      await token.connect(account1).approve(staking.target, stakingAmount);
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;

      await staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS);

      expect(await staking.getStakesLength(account1.address)).to.be.equal(4)
      let now = Math.floor(Date.now()/1000);
      expect(await staking.calculateEarlyUnstakePercentage(now,now,now+ONE_MONTH_IN_SECS)).to.be.equal(900)

      await expect(staking.connect(account1).unstake(3)).to.emit(
        staking,
        "LogUnstake",
      );
    });

        // ************* calculateEarlyUnstakePercentage **************
    it("should calculate Early Unstake Percentage ", async () => {
      const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;

      let now = Math.floor(Date.now()/1000);
    expect(await staking.calculateEarlyUnstakePercentage(ONE_MONTH_IN_SECS-1,now,now+ONE_MONTH_IN_SECS)).to.be.equal(100)
    })

        // ************* sync **************
    it("should call sync", async () => {
    
      await expect(staking.connect(account1).sync()).to.emit(
        staking,
        "LogSync",
      );
    });


    it("should not call sync if contract is paused", async () => {
      await staking.pause(true);
      await expect(staking.connect(account1).sync()).to.be.reverted
    });

   // ************* pause **************
    it("should revert is caller is not owner for function paused", async () => {
      await expect(staking.connect(account1).pause(true)).to.be.reverted;
    });


   // ************* pendingRewards **************
    it("should revert is caller is not owner for function paused", async () => {
      expect(await staking.connect(account1).pendingRewards(account1.address)).to.be.eq(13150745814301403n)
    });





    // ************* admin actions **************
    it("should revert if the caller is not pool", async () => {
      await expect(staking.connect(account1).setWeight(201)).to.be.revertedWithCustomError(staking,"OnlyFactory")
    });
    it("should revert non owner try to change pool weight", async () => {
      await expect(poolController.connect(account1).changePoolWeight(staking.target,201)).to.be.reverted
    });
    it("should allow to change pool weight", async () => {
      await poolController.changePoolWeight(staking.target,201)
      expect(await poolController.totalWeight()).to.be.equal(1001)
    });
    it("should revert non owner try to change pika per sec", async () => {
      await expect(poolController.connect(account1).updatePikaPerSecond(toGWei(0.1))).to.be.reverted
    });
    it("should allow to change pika per sec", async () => {
      await poolController.updatePikaPerSecond(toGWei(0.1))
    });

  });
});
