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
    const [owner, _, account1, account2,verifierAddress] = await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");
    const ERC20 =  await ethers.getContractFactory("Token")
    const token = await upgrades.deployProxy(
      pikamoon,
      ["PIKAMoon", "PIKA", owner.address, owner.address],
      { initializer: "initialize" },
    );
    const lptoken = await ERC20.deploy(
    "LPToken", "LP", toWei(500000000000000000)
    );

    const PoolController = await ethers.getContractFactory("PoolController");
    const poolController = await upgrades.deployProxy(PoolController, [], {
      initializer: "initialize",
    });

    const PikaStaking = await ethers.getContractFactory("PikaStakingPool");

    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [ZeroAddress, token.target, poolController.target, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;

    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [token.target, ZeroAddress, poolController.target, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;
    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [token.target, token.target, ZeroAddress, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;

    const staking = await upgrades.deployProxy(
      PikaStaking,
      [token.target, token.target, poolController.target, 200],
      { initializer: "initialize" },
    );
    const lpstaking = await upgrades.deployProxy(
        PikaStaking,
        [lptoken.target, token.target, poolController.target, 200],
        { initializer: "initialize" },
      );
    await poolController.registerPool(lpstaking.target);
    await poolController.registerPool(staking.target);
    await token.mint(poolController.target, toGWei(5_000_000_000));
    await token.mint(account2.address, toGWei(50));
    await token.mint(account1.address, toGWei(50));
    await token.excludeFromTax(staking.target, true);
    await token.excludeFromTax(poolController.target, true);

    await lptoken.mint(poolController.target, toWei(5000000000));
    await lptoken.mint(account2.address, toWei(50));
    await lptoken.mint(account1.address, toWei(50));

    return { token,lptoken, staking,lpstaking, owner, account1, account2, poolController,verifierAddress };
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
        let stakingAmount = toWei(50);
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
        const signature = await owner.signMessage(ethers.toBeArray(message));
        await time.increase(30 * 24 * 60 * 60);
        console.log("bal before",await token.balanceOf(staking.target))
        await expect(
          lpstaking
            .connect(account1)
            .claimRewards(0, true, signature, _time),
        ).to.emit(staking, "LogStake");
        expect(await lpstaking.getStakesLength(account1.address)).to.be.equal(1);
        expect(await staking.getStakesLength(account1.address)).to.be.equal(1);
       console.log("bal after",await token.balanceOf(staking.target))
      });

      it("should restake after claiming with restake", async () => {
        let _time = new Date().getTime();
        const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
        const message = encodeAndHash(
          account1.address,
          500,
          true,
          _time,
        );
        const signature = await owner.signMessage(ethers.toBeArray(message));
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
      it("should allow unstake ", async () => {
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
