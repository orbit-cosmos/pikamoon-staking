import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, DirectStaking,PoolFactory } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);

function encodeAndHash(address: Address | string, amount: bigint | number,nonce: bigint | number) {
  return ethers.solidityPackedKeccak256(
    ["address", "uint256","uint256"],
    [address, amount,nonce],
  );
}
describe("Pika Staking", function () {
  async function deployICOFixture() {
    const [owner, stakingReward, account1, account2] =
      await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");

    const token = await upgrades.deployProxy(
      pikamoon,
      ["PIKAMoon", "PIKA", owner.address, owner.address],
      { initializer: "initialize" },
    );

    const PoolFactory = await ethers.getContractFactory("PoolFactory");
    const poolFactory = await upgrades.deployProxy(PoolFactory, [], {
      initializer: "initialize",
    });

    const PikaStaking = await ethers.getContractFactory("DirectStaking");
    const staking = await upgrades.deployProxy(
      PikaStaking,
      [token.target, token.target, poolFactory.target, 200],
      { initializer: "initialize" },
    );

    await poolFactory.registerPool(staking.target);
    await token.mint(poolFactory.target, toGWei(5_000_000_000));
    await token.mint(account2.address, toGWei(50));
    await token.mint(account1.address, toGWei(50));
    await token.excludeFromTax(staking.target, true);

    return { token, staking, owner, account1, account2 };
  }

  describe("test cases", async function () {
    let token: PikaMoon,
      staking: DirectStaking,
      owner: HardhatEthersSigner,
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
      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.emit(staking, "LogStake");
      expect(await token.balanceOf(account1.address)).to.be.equal("0");
    });

    it("should allow claim if contract is paused", async () => {
      await staking.pause(true);
      let time = new Date().getTime()
      const message = encodeAndHash(account1.address, 500,time);
      const signature = await owner.signMessage(ethers.toBeArray(message));

      await expect(
        staking.connect(account1).claimRewards(500, signature,time),
      ).to.be.revertedWithCustomError(staking, "ContractIsPaused");

      await staking.pause(false);
    });
    it("should not allow claim if tampered", async () => {
      let time = new Date().getTime()
      const message = encodeAndHash(account1.address, 500, time);
      const signature = await owner.signMessage(ethers.toBeArray(message));

      await expect(
        staking.connect(account1).claimRewards(501, signature,time),
      ).to.be.revertedWithCustomError(staking, "WrongHash");
    });

    it("should not allow claim if claim % is wrong", async () => {
      let time = new Date().getTime()
      const message = encodeAndHash(account1.address, 500,time);
      const signature = await owner.signMessage(ethers.toBeArray(message));

      await expect(
        staking.connect(account1).claimRewards(10001, signature,time),
      ).to.be.reverted
    });
    it("should allow claim", async () => {
      let time = new Date().getTime()
      const message = encodeAndHash(account1.address, 500,time)
      const signature = await owner.signMessage(ethers.toBeArray(message));

      await expect(
        staking.connect(account1).claimRewards(500, signature,time),
      ).to.emit(staking, "LogClaimRewards");
    });

    it("should allow claim", async () => {
      let time = new Date().getTime()
      const message = encodeAndHash(account1.address, 500,time)
      const signature = await owner.signMessage(ethers.toBeArray(message));

      await expect(
        staking.connect(account1).claimRewards(500, signature,time),
      ).to.emit(staking, "LogClaimRewards");



      await expect(
        staking.connect(account1).claimRewards(500, signature,time),
      ).to.be.reverted




    });

    it("should allow unstake if contract is paused", async () => {
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
  });
});
